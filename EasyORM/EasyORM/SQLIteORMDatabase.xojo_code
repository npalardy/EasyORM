#tag Class
Class SQLIteORMDatabase
Inherits ORMDatabase
	#tag Method, Flags = &h1
		Protected Function AutoincrementClause() As string
		  return "autoincrement"
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
		  
		  Dim localDB As New SQLiteDatabase
		  
		  If mDBPath.Trim <> "" Then
		    localDB.DatabaseFile = New folderitem(mDBPath, FolderItem.PathModes.Native)
		    
		    localDB.CreateDatabase
		    
		  End If
		  
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
		    
		    // ios has no support for DATE types (only DATETIME !)
		  Case "Date"
		    #If TargetIOS
		      Raise New UnsupportedOperationException("iOS does not support the DATE type")
		    #Else
		      If colValue Is Nil Then
		        returnValue = Nil 
		      Else
		        // we inserted this as ISO 8601 - YYYY-MM-DDThh:mm:ss+HH:mm
		        returnValue = DateFromISO8601String(colValue.StringValue)
		      End If
		    #EndIf
		    
		  Case "Datetime"
		    If colValue Is Nil Then
		      returnValue = Nil 
		    Else
		      // we inserted this as ISO 8601 - YYYY-MM-DDThh:mm:ss+HH:mm
		      returnValue = DateTimeFromISO8601String(colValue.StringValue)
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
		  Dim rs As rowset = mDatabase.SelectSQL("pragma table_xinfo( " + tblName + " )")
		  // we get back a rowset like
		  // CID  NAME             TYPE       NOTNULL    DEFAULT  PK COL  Hidden
		  // 0    DateColumn       Text       0          NULL     2       0
		  // 1    DateTimeColumn   Text       0          NULL     0       0
		  // 2    Untitled1        Integer    0          NULL     1       0
		  
		  // PK Col is the ODER in the primary key constraint 
		  // ie in the above it was Primary key(Untitled1, DateColumn))
		  //    so untitled1 was FIRST component, datecolumn was second, etc
		  Dim pkColumns As New dictionary
		  
		  While rs.AfterLastRow <> True
		    
		    If rs.Column("pk").IntegerValue <> 0 Then
		      pkColumns.Value(rs.Column("pk").IntegerValue) = rs.Column("name").StringValue
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
		  If criteria.Trim <> "" Then
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
		      #If TargetIOS 
		        Raise New UnsupportedOperationException("iOS does not support the DATE type")
		      #Else
		        If prop.Value(instance).DateValue Is Nil Then
		          lstColumnValues.add Nil
		        Else
		          #Pragma breakonexceptions False
		          Try
		            lstColumnValues.add ToISO8601String(prop.Value(instance).DateValue)
		          Catch
		            lstColumnValues.add Nil
		          End Try
		        End If
		      #EndIf
		    Case "Datetime"
		      If prop.Value(instance).DateTimeValue Is Nil Then
		        lstColumnValues.add Nil
		      Else
		        #Pragma breakonexceptions False
		        Try
		          lstColumnValues.add ToISO8601String(prop.Value(instance).DateTimeValue)
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

	#tag Method, Flags = &h0
		Function Last(classInfo as Introspection.TypeInfo, extraCriteria as string = "") As Variant
		  // for sqlite 
		  
		  // generate a UNIQUE NAME for a temporary table
		  
		  // create the temporary
		  //     create temporary table __justfortesting As Select dateColumn, untitled1 from mycustomtable LIMIT 1
		  
		  // pragma table_info(__justfortesting) ;
		  //     this gets the columns in the order the select would have created define them
		  //     we can use this to generate the reverse order by 
		  
		  // now write a select that orders everything, even a custom query, descending
		  //     Select * from __justfortesting order by dateColumn, untitled1 ;
		  //     Select * from __justfortesting order by dateColumn desc, untitled1 desc ;
		  
		  // remove the temp table
		  //     drop table __justfortesting ;
		  
		  // now we know the right order by clause query the original table
		  
		  Dim tblName As String = classInfo.Name
		  
		  // craft the query stmt
		  Dim stmt As String = "select * from " + tblName 
		  If extraCriteria.Trim <> "" Then
		    stmt = stmt + " where " + extraCriteria
		  End If
		  
		  // generate a unique name for the tempoarary
		  Dim tmpTblNameRoot As String = "__temp" 
		  Dim tmpTblName As String
		  Dim existsRS As Rowset
		  While True
		    tmpTblName = tmpTblNameRoot + System.Microseconds.ToString(Nil, "#########0")
		    existsRS = mDatabase.SelectSQL("select * from sqlite_master where type = 'table' and name = ?", tmpTblName )
		    If existsRS.BeforeFirstRow And existsRS.AfterLastRow Then
		      Exit While
		    End If
		  Wend
		  
		  // create temporary table __justfortesting As Select dateColumn, untitled1 from mycustomtable ;
		  mDatabase.ExecuteSQL("create temporary table " + tmpTblName + " as " + stmt + " limit 1" )
		  
		  // pragma table_info(__justfortesting) ;
		  Dim table_infoRS As Rowset = mDatabase.SelectSQL("pragma table_info(" + tmpTblName + ")" )
		  Dim reverseorderby As String
		  While table_infoRS <> Nil And table_infoRS.AfterLastRow = False
		    
		    If reverseorderby.Trim <> "" Then
		      reverseorderby = reverseorderby + ", " 
		    End If
		    
		    reverseorderby = reverseorderby + table_infoRS.Column("name").StringValue + " desc"
		    
		    table_infoRS.MoveToNextRow
		  Wend
		  
		  // drop the temporary table
		  mDatabase.ExecuteSQL("drop table " + tmpTblName )
		  
		  stmt = stmt + " order by " + reverseorderby
		  
		  // note this _may_ let a database exception leak out to the world !
		  Dim rs As rowset = mDatabase.SelectSQL(stmt)
		  
		  If rs.BeforeFirstRow And rs.AfterLastRow Then
		    Return Nil
		  End If
		  
		  If rs.RowCount = 0 Then
		    Return Nil
		  End If
		  
		  Return ToInstance(classInfo, rs)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function MapXojoTypeToDBType(propTypeName as string) As string
		  // Calling the overridden superclass method.
		  Var returnValue As String
		  
		  Select Case propTypeName
		  Case "Integer"
		    returnValue = "Integer"
		  Case "Int64"
		    returnValue = "Integer"
		  Case "Int32"
		    returnValue = "Integer"
		  Case "Int16"
		    returnValue = "Integer"
		  Case "Int8"
		    returnValue = "Integer"
		  Case "Uinteger"
		    returnValue = "Integer"
		  Case "Uint64"
		    returnValue = "Integer"
		  Case "Uint32"
		    returnValue = "Integer"
		  Case "UInt16"
		    returnValue = "Integer"
		  Case "UInt8"
		    returnValue = "Integer"
		  Case "Double"
		    returnValue = "REAL"
		  Case "Single"
		    returnValue = "REAL"
		  Case "Currency"
		    returnValue = "REAL"
		  Case "String"
		    returnValue = "TEXT"
		  Case "Color"
		    returnValue = "INTEGER"
		  Case "Date"
		    returnValue = "TEXT"
		  Case "Datetime"
		    returnValue = "TEXT"
		  Case "Boolean"
		    returnValue = "INTEGER"
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
		    Dim rs As RowSet = mDatabase.SelectSQL("select count(*) from sqlite_master where type  = 'table' and name like '" + tableName + "'" )
		    
		    exists = rs.ColumnAt(0).IntegerValue <> 0
		    
		  Catch dex As DatabaseException
		    
		  End Try
		  
		  Return exists
		End Function
	#tag EndMethod


	#tag Note, Name = about
		
		as of this writing this is really a "SQLiteOrmDatabase"
		but hey ........ we'll lifty a super class out later
		
	#tag EndNote


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mDBPath
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  // settable only Until we CONNECT Then its read only
			  If mConnected Then
			    Return
			  End If
			  
			  mDBPath = value
			End Set
		#tag EndSetter
		DBPath As String
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mDBPath As String
	#tag EndProperty


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
			Name="DBPath"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
