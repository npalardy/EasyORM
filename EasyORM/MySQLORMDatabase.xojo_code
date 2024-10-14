#tag Class
Class MySQLORMDatabase
Inherits ORMDatabase
	#tag Method, Flags = &h1
		Protected Function AutoincrementClause() As string
		  return "auto_increment"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Close()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Connect()
		  If mConnected = True Then
		    Return
		  End If
		  
		  mConnected = False
		  
		  Dim localDB As New MySQLCommunityServer
		  
		  localDB.Host = mHost
		  localDB.Port = mPort
		  localDB.DatabaseName = mDatabaseName
		  localDB.Username = mUsername
		  localDB.Password = mPassword
		  
		  If localDB.Connect = True Then
		    
		    mConnected = True
		    
		    mDatabase = localDB
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  // Calling the overridden superclass constructor.
		  Super.Constructor
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CreateTable(tInfo As Introspection.TypeInfo)
		  
		  // ok we walk through ALL the public properties
		  // and create suitable columns for them
		  // attributes may be applied to any property
		  //   PrimaryKey
		  //   Autoincrement
		  //   NotNull
		  //   Unique [requires attrvalue => ON CONFLICT | ROLLBACK | ABORT | FAIL | IGNORE | Replace]
		  //   Default [requires attrrvalue => CURRENT_TIMESTAMP | numeric-literal | String-literal | NULL | True | False | CURRENT_TIME | CURRENT_DATE ]
		  
		  // SOME attributes can be added ON the class itself
		  //   for instance 
		  //   CONSTRAINT name
		  //       PRIMARY   ded-column lict- (, indexed-column )* use
		  //    |  UNIQUE indexed-column (, indexed-column )* conflict-clause
		  //    |  CHECK ( expr )
		  //    |  FOREIGN KEY column-name (, column-name)* foreign-key-clause
		  
		  // see IF this table exists
		  
		  Dim tblName As String = tInfo.Name
		  
		  If TableExists(tblName) = True Then
		    Return
		  End If
		  
		  // walk through this things public properties
		  // and create columns for them all
		  
		  Dim lstPropInfo() As Introspection.PropertyInfo = tInfo.GetProperties
		  
		  Dim lstColumnDefs() As String
		  
		  For Each prop As Introspection.PropertyInfo In lstPropInfo
		    
		    If prop.IsPublic = False Then
		      Continue
		    End If
		    
		    Dim thisDef As String = prop.Name
		    
		    // the type for sqlite ?
		    // we handle instrinsics like numerics, colors, strings, datetime, booleans
		    // in general we just use whats given BUT we do need to alter some
		    Try
		      thisDef = thisdef + " " + MapXojoTypeToDBType(prop.PropertyType.Name)
		    Catch UnMappedTypeException
		      Continue
		    End Try
		    // constraints
		    Dim lstAttrs() As Introspection.AttributeInfo = prop.GetAttributes
		    
		    // duplicate attributes arent permitted anyway
		    
		    For Each attr As Introspection.AttributeInfo In lstAttrs
		      
		      // we only recognize a few (see above)
		      Select Case attr.Name
		        
		      Case "PrimaryKey"
		        thisDef = thisdef + " " + PrimaryKeyClause()
		        
		      Case "Autoincrement"
		        thisDef = thisdef + " " + AutoincrementClause()
		        
		      Case "NotNull"
		        thisDef = thisdef + NotNullClause()
		        
		        //   Unique [requires attrvalue => ON CONFLICT | ROLLBACK | ABORT | FAIL | IGNORE | Replace]
		        //   Default [requires attrrvalue => CURRENT_TIMESTAMP | numeric-literal | String-literal | NULL | True | False | CURRENT_TIME | CURRENT_DATE ]
		        
		      End Select
		    Next
		    
		    lstColumnDefs.add thisDef
		  Next
		  
		  // craft the create table stmt
		  Dim stmt As String = "create table if not exists " + tblName + " (" + Join(lstColumnDefs, "," ) + ")"
		  
		  // note this _may_ let a database exception leak out to the world !
		  mDatabase.ExecuteSQL(stmt)
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function CustomConvertPropValue(prop as introspection.PropertyInfo, colValue as Variant) As Variant
		  // here we only handle any property / column values that we need to treat specially
		  // typically that will be in INSERT
		  
		  Var returnValue As Variant
		  
		  Select Case prop.PropertyType.FullName
		    
		  Case "Date"
		    If colValue Is Nil Then
		      returnValue = Nil 
		    Else
		      // we inserted this as SQLDateTime - YYYY-MM-DDT hh:mm:ss
		      returnValue = DateFromSqlDateTimeString(colValue.StringValue)
		    End If
		    
		  Case "Datetime"
		    If colValue Is Nil Then
		      returnValue = Nil 
		    Else
		      // we inserted this as SQLDateTime - YYYY-MM-DDT hh:mm:ss
		      returnValue = DateTimeFromSqlDateTimeString(colValue.StringValue)
		    End If
		    
		  Else
		    returnValue = Super.CustomConvertPropValue(prop, colValue)
		  End Select
		  
		  return returnValue
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Delete(instance as BaseTable)
		  Dim tInfo As Introspection.TypeInfo = Introspection.GetType(instance)
		  
		  Dim tblName As String = tInfo.Name
		  
		  If TableExists(tblName) = False Then
		    Return
		  End If
		  
		  // delete a specific instance
		  
		  // if tbl has a primary key use that
		  Dim rs As rowset = mDatabase.TableColumns(tblName)
		  // we get back a rowset like
		  // ColumnName, FieldType, IsPrimary, NotNull and Length.
		  
		  Dim pkColumns As New dictionary
		  
		  While rs.AfterLastRow <> True
		    
		    If rs.Column("IsPrimary").IntegerValue <> 0 Then
		      pkColumns.Value(rs.Column("IsPrimary").IntegerValue) = rs.Column("ColumnName").StringValue
		    End If
		    
		    rs.MoveToNextRow
		  Wend
		  
		  If pkColumns.KeyCount > 0 Then
		    
		    dim props() as Introspection.PropertyInfo = tinfo.GetProperties
		    
		    Dim stmt As String = "delete from " + tblName + " where "
		    
		    Dim lstColumnValues() As Variant
		    
		    For Each key As Integer In pkColumns.Keys
		      stmt = stmt + pkColumns.Value(key) + " = ? "
		      
		      // find this column in the props of the table
		      // go backwards in case a property has been shadowed properly 
		      // although some have no clue how to do it right so it actually works
		      For i As Integer = props.ubound DownTo 0
		        If props(i).Name = pkColumns.Value(key) Then
		          lstColumnValues.append props(i).Value(instance)
		          Exit For
		        End If
		      Next
		    Next
		    
		    // note this _may_ let a database exception leak out to the world !
		    Try
		      mDatabase.ExecuteSQL(stmt, lstColumnValues)
		    Catch DatabaseException
		      Break
		    End Try
		    
		    
		  Else
		    // if not try & find the right one with all the columns so we limit any damage
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Delete(tInfo as Introspection.TypeInfo, criteria as string)
		  Dim tblName As String = tInfo.Name
		  
		  If TableExists(tblName) = False Then
		    Return
		  End If
		  
		  Dim stmt As String = "delete from " + tblName 
		  If Trim(criteria) <> "" Then
		    stmt = stmt + " where " + criteria
		  End If
		  
		  Try
		    mDatabase.ExecuteSQL(stmt)
		  Catch DatabaseException
		    Break
		  End Try
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteTable(classInfo as Introspection.TypeInfo)
		  
		  Dim tblName As String = classInfo.Name
		  
		  // craft the drop table stmt
		  Dim stmt As String = "drop table if exists " + tblName
		  
		  // note this _may_ let a database exception leak out to the world !
		  mDatabase.ExecuteSQL(stmt)
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Insert(instance as BaseTable)
		  Dim tInfo As Introspection.TypeInfo = Introspection.GetType(instance)
		  
		  // see IF this table exists
		  
		  Dim tblName As String = tInfo.Name
		  
		  If TableExists(tblName) = False Then
		    Return
		  End If
		  
		  // walk through this things public properties
		  // and create columns for them all
		  
		  Dim lstPropInfo() As Introspection.PropertyInfo = tInfo.GetProperties
		  
		  Dim lstColumns() As String
		  Dim lstPlaceHolders() As String
		  Dim lstColumnValues() As Variant
		  
		  For Each prop As Introspection.PropertyInfo In lstPropInfo
		    
		    If prop.IsPublic = False Then
		      Continue
		    End If
		    
		    Dim thisDef As String = prop.Name
		    lstColumns.Add prop.Name
		    lstPlaceHolders.add "?"
		    
		    // the type for sqlite ?
		    // we handle instrinsics like numerics, colors, strings, datetime, booleans
		    // in general we just use whats given BUT we do need to alter some
		    Select Case prop.PropertyType.Name
		    Case "Integer"
		      lstColumnValues.add prop.Value(instance)
		    Case "Int64"
		      lstColumnValues.add prop.Value(instance)
		    Case "Int32"
		      lstColumnValues.add prop.Value(instance)
		    Case "Int16"
		      lstColumnValues.add prop.Value(instance)
		    Case "Int8"
		      lstColumnValues.add prop.Value(instance)
		    Case "Uinteger"
		      lstColumnValues.add prop.Value(instance)
		    Case "Uint64"
		      lstColumnValues.add prop.Value(instance)
		    Case "Uint32"
		      lstColumnValues.add prop.Value(instance)
		    Case "UInt16"
		      lstColumnValues.add prop.Value(instance)
		    Case "UInt8"
		      lstColumnValues.add prop.Value(instance)
		    Case "Double"
		      lstColumnValues.add prop.Value(instance)
		    Case "Single"
		      lstColumnValues.add prop.Value(instance)
		    Case "Currency"
		      lstColumnValues.add prop.Value(instance)
		    Case "String"
		      lstColumnValues.add prop.Value(instance)
		    Case "Color"
		      lstColumnValues.add prop.Value(instance)
		    Case "Date"
		      If prop.Value(instance).DateValue Is Nil Then
		        lstColumnValues.add Nil
		      Else
		        #Pragma breakonexceptions False
		        Try
		          lstColumnValues.add prop.Value(instance).DateValue.SQLDateTime
		        Catch
		          lstColumnValues.add Nil
		        End Try
		      End If
		    Case "Datetime"
		      If prop.Value(instance).DateTimeValue Is Nil Then
		        lstColumnValues.add Nil
		      Else
		        #Pragma breakonexceptions False
		        Try
		          lstColumnValues.add prop.Value(instance).DateTimeValue.SQLDateTime
		        Catch
		          lstColumnValues.add Nil
		        End Try
		      End If
		    Case "Boolean"
		      lstColumnValues.add prop.Value(instance)
		    Else
		      Continue // no idea what to properly do with this so bail and do nothing
		    End Select
		    
		  Next
		  
		  // craft the create table stmt
		  Dim stmt As String = "insert into " + tblName + " (" + Join(lstColumns, "," ) + ") values (" + Join(lstPlaceHolders, "," ) + ")"
		  
		  // note this _may_ let a database exception leak out to the world !
		  mDatabase.ExecuteSQL(stmt, lstColumnValues)
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function MapXojoTypeToDBType(propTypeName as string) As string
		  // Calling the overridden superclass method.
		  Var returnValue As String
		  
		  Select Case propTypeName
		  Case "Integer"
		    returnValue = "INT"
		  Case "Int64"
		    returnValue = "BIGINT"
		  Case "Int32"
		    returnValue = "INT"
		  Case "Int16"
		    returnValue = "MEDIUMINT"
		  Case "Int8"
		    returnValue = "TINYINT"
		  Case "Uinteger"
		    returnValue = "Integer"
		  Case "Uint64"
		    returnValue = "INT"
		  Case "Uint32"
		    returnValue = "INT"
		  Case "UInt16"
		    returnValue = "MEDIUMINT"
		  Case "UInt8"
		    returnValue = "TINYINT"
		  Case "Double"
		    returnValue = "FLOAT(53)" // 8 bytes
		  Case "Single"
		    returnValue = "FLOAT(10)" // 4 bytes
		  Case "Currency"
		    returnValue = "DECIMAL(15,4)" // exact
		  Case "String"
		    returnValue = "TEXT"
		  Case "Color"
		    returnValue = "INTEGER"
		  Case "Date"
		    returnValue = "DATETIME"
		  Case "Datetime"
		    returnValue = "DATETIME"
		  Case "Boolean"
		    returnValue = "TINYINT"
		  Else
		    Break // no idea what to properly do with this so bail and do nothing
		    Raise New UnMappedTypeException("unhandled type " + propTypeName)
		  End Select
		  
		  return returnValue
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function NotNullClause() As String
		  return "not null"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function PrimaryKeyClause() As string
		  return "primary key"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function TableExists(tableName as string) As Boolean
		  Dim exists As Boolean
		  
		  Try
		    Dim rs As RowSet = mDatabase.SelectSQL("SELECT count(*) FROM information_schema.tables WHERE table_schema = '" + mDatabaseName +"' and table_name = '" + tableName + "'")
		    
		    exists = rs.ColumnAt(0).IntegerValue <> 0
		    
		  Catch dex As DatabaseException
		    
		  End Try
		  
		  Return exists
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mDatabaseName
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  // settable only Until we CONNECT Then its read only
			  If mConnected Then
			    Return
			  End If
			  
			  mDatabaseName = value
			End Set
		#tag EndSetter
		DatabaseName As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mHost
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  // settable only Until we CONNECT Then its read only
			  If mConnected Then
			    Return
			  End If
			  
			  mHost = value
			End Set
		#tag EndSetter
		Host As String
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mDatabaseName As string
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mHost As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPassword As string
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPort As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mUsername As string
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Setter
			Set
			  // settable only Until we CONNECT Then its read only
			  If mConnected Then
			    Return
			  End If
			  
			  mPassword = value
			End Set
		#tag EndSetter
		Password As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mPort
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  // settable only Until we CONNECT Then its read only
			  If mConnected Then
			    Return
			  End If
			  
			  mPort = value
			End Set
		#tag EndSetter
		Port As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mUsername
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  // settable only Until we CONNECT Then its read only
			  If mConnected Then
			    Return
			  End If
			  
			  mUsername = value
			End Set
		#tag EndSetter
		Username As String
	#tag EndComputedProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="IsConnected"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Host"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Port"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="DatabaseName"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Password"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Username"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
