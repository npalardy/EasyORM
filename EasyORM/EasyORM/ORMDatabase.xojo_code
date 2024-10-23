#tag Class
Class ORMDatabase
	#tag Method, Flags = &h1
		Protected Function AutoincrementClause() As string
		  Return "autoincrement"
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Close()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Connect()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Constructor()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CreateTable(classInfo as Introspection.TypeInfo)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function CustomConvertPropValue(prop as introspection.PropertyInfo, colValue as Variant) As Variant
		  
		  return colValue
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Protected Function DateFromISO8601String(s as string) As Date
		  // this was inserted as date as yyyy-MM-DD HH:MM:SS [+/-]hh:mm:ss.sss
		  // hh is HOURS offset from GMT
		  // mm is minutes offset from GMT
		  // we inserted this as ISO 8601 - YYYY-MM-DDThh:mm:ss+HH:mm
		  
		  Dim parts() As String
		  Dim yearPart As String
		  Dim timePart As String
		  Dim gmtPart As String
		  
		  Dim year, month, day, hour, minute, second As Integer
		  Dim gmtOffset As Double
		  parts = Split(s," ")
		  Try
		    yearPart = parts(0)
		    timePart = parts(1)
		    gmtPart = parts(2)
		    
		    parts = Split(yearPart, "-")
		    year = Val(parts(0))
		    month = Val(parts(1))
		    day = Val(parts(2))
		    
		    parts = Split(timePart, ":")
		    hour = Val(parts(0))
		    minute = Val(parts(1))
		    second = Val(parts(2))
		    
		    Dim isNegGMT As Boolean
		    If Left(gmtPart,1) = "-" Then
		      isNegGMT = True
		    End If
		    gmtPart = ReplaceAll(gmtPart,"-", "")
		    gmtPart = ReplaceAll(gmtPart,"+", "")
		    parts = Split(gmtPart, ":")
		    gmtOffset = Val(parts(0)) + Val(parts(1))/60 + val(parts(2)) / 3600 // <<<<<<<<<< for date gmtOffset is in hours
		    If isNegGMT Then
		      gmtOffset = gmtOffset * -1
		    End If
		    
		    Return New date(year, month, day, hour, minute, second, gmtOffset )
		  Catch OutOfBoundsException
		    
		    Break
		  End Try
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Protected Function DateFromSqlDateTimeString(sqldateString as string) As Date
		  
		  // dates are easy
		  
		  Dim tmpDate As New date
		  tmpDate.SQLDateTime = sqldateString
		  
		  Return tmpDate
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function DateTimeFromISO8601String(s as string) As datetime
		  // this was inserted as date as yyyy-MM-DD HH:MM:SS [+/-]hh:mm:ss.sss
		  // hh is HOURS offset from GMT
		  // mm is minutes offset from GMT
		  // we inserted this as ISO 8601 - YYYY-MM-DDThh:mm:ss+HH:mm
		  
		  Dim parts() As String
		  Dim yearPart As String
		  Dim timePart As String
		  Dim gmtPart As String
		  
		  Dim year, month, day, hour, minute, second As Integer
		  Dim gmtOffset As Double
		  
		  parts = s.Split(" ")
		  Try
		    yearPart = parts(0)
		    timePart = parts(1)
		    gmtPart = parts(2)
		    
		    parts = yearPart.Split( "-")
		    year = Val(parts(0))
		    month = Val(parts(1))
		    day = Val(parts(2))
		    
		    parts = timePart.Split(":")
		    hour = Val(parts(0))
		    minute = Val(parts(1))
		    second = Val(parts(2))
		    
		    Dim isNegGMT As Boolean
		    If gmtPart.Left(1) = "-" Then
		      isNegGMT = True
		    End If
		    gmtPart = gmtPart.ReplaceAll("-","")
		    gmtPart = gmtPart.ReplaceAll("+","")
		    parts = gmtPart.Split( ":")
		    gmtOffset = Val(parts(0)) * 60 * 60 + Val(parts(1)) * 60 + val(parts(2)) // <<<<<<<<<< for dateTime gmtOffset is in seconds !
		    If isNegGMT Then
		      gmtOffset = gmtOffset * -1
		    End If
		    Return New datetime(year, month, day, hour, minute, second, 0, New TimeZone( gmtOffset ) )
		    
		  Catch OutOfBoundsException
		    
		    Break
		  End Try
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function DateTimeFromSqlDateTimeString(sqldateString as string) As Datetime
		  
		  // sql dates are easy
		  Dim parts() As String = sqldateString.ReplaceAll("-", " ").ReplaceAll(":", " ").Split(" ")
		  
		  If parts.count < 3 Then
		    Return Nil
		  End If
		  
		  Dim tmpDateTime As New DateTime(parts(0).ToInteger, parts(1).ToInteger, parts(2).ToInteger)
		  
		  Return tmpDateTime
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Delete(instance as BaseTable)
		  // delete a specific instance
		  
		  // if tbl has a primary key use that
		  //
		  break
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Delete(classInfo as Introspection.TypeInfo, criteria as string)
		  break
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DeleteTable(classInfo as Introspection.TypeInfo)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Find(tInfo as Introspection.TypeInfo, extraCriteria as string = "") As BaseTable()
		  Dim tblName As String = tInfo.Name
		  
		  // craft the query stmt
		  Dim stmt As String = "select * from " + tblName 
		  If extraCriteria.Trim <> "" Then
		    stmt = stmt + " where " + extraCriteria
		  End If
		  
		  // note this _may_ let a database exception leak out to the world !
		  Dim rs As rowset = mDatabase.SelectSQL(stmt)
		  
		  Dim items() As BaseTable
		  If rs Is Nil Then 
		    Return items()
		  End If
		  
		  While rs.AfterLastRow <> True
		    
		    items.add ToInstance(tInfo, rs)
		    
		    rs.MoveToNextRow
		    
		  Wend
		  
		  return items
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function First(tInfo as Introspection.TypeInfo, extraCriteria as string = "") As Variant
		  
		  Dim tblName As String = tInfo.Name
		  
		  // first is .. interstings
		  
		  // craft the query stmt
		  Dim stmt As String = "select * from " + tblName 
		  If extraCriteria.Trim <> "" Then
		    stmt = stmt + " where " + extraCriteria
		  End If
		  
		  // note this _may_ let a database exception leak out to the world !
		  Dim rs As rowset = mDatabase.SelectSQL(stmt)
		  
		  If rs.BeforeFirstRow And rs.AfterLastRow Then
		    Return Nil
		  End If
		  
		  If rs.RowCount = 0 Then
		    Return Nil
		  End If
		  
		  Return ToInstance(tinfo, rs)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Insert(instance as BaseTable)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Last(classInfo as Introspection.TypeInfo, extraCriteria as string = "") As Variant
		  // this is the dead stupid but functional way
		  // DB's that CAN do order by desc limit 1 should override
		  // BUT they have to be careful to preserve the EXTRA CRITERIA searching
		  // some db's may make it tricky to generate the correct oder by reverse orde rrstsmt with a specific user where clause
		  
		  Dim tblName As String = classInfo.Name
		  
		  // last is .. interesting
		  
		  // craft the query stmt
		  Dim stmt As String = "select * from " + tblName 
		  If extraCriteria.Trim <> "" Then
		    stmt = stmt + " where " + extraCriteria
		  End If
		  
		  // note this _may_ let a database exception leak out to the world !
		  Dim rs As rowset = mDatabase.SelectSQL(stmt)
		  
		  If rs.BeforeFirstRow And rs.AfterLastRow Then
		    Return Nil
		  End If
		  
		  If rs.RowCount = 0 Then
		    Return Nil
		  End If
		  
		  For i As Integer = 0 To rs.RowCount - 2
		    rs.MoveToNextRow
		  Next
		  
		  Return ToInstance(classInfo, rs)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function MapXojoTypeToDBType(propTypeName as string) As string
		  // custom handling of the XOJO property type to DB TYEP name mapping
		  Return propTypeName
		  
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
		  
		  Return exists
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ToInstance(tInfo as Introspection.TypeInfo, rs as rowset) As Variant
		  
		  Dim obj As BaseTable 
		  
		  // // find the LAST zero param constructor in tInfo
		  Dim constructors() As Introspection.ConstructorInfo = tInfo.GetConstructors
		  
		  For i As Integer = constructors.LastIndex DownTo 0
		    
		    If constructors(i).GetParameters.Count = 0 Then
		      
		      obj = constructors(i).Invoke()
		      
		      Exit For
		    End If
		  Next
		  
		  If obj Is Nil Then 
		    Return Nil
		  End If
		  
		  Dim propinfos() As introspection.PropertyInfo = tInfo.GetProperties
		  
		  // load all the columns into the properties
		  For i As Integer = 0 To rs.ColumnCount - 1
		    
		    Dim col As DatabaseColumn = rs.ColumnAt(i)
		    
		    // find the property with this name
		    Dim prop As introspection.PropertyInfo
		    
		    For j As Integer = 0 To propinfos.LastIndex
		      If propinfos(j).Name = col.Name Then
		        prop = propinfos(j)
		        Exit For
		      End If
		    Next
		    
		    If prop <> Nil Then
		      prop.Value(obj) = CustomConvertPropValue( prop, col.Value )
		    End If
		    
		  Next
		  
		  // and return the instance
		  Return obj
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetWeb and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Protected Function ToISO8601String(d as date) As string
		  // formats a date as yyyy-MM-DD HH:MM:SS [+/-]hh:mm:ss.sss
		  // hh is HOURS offset from GMT
		  // mm is minutes offset from GMT
		  
		  Dim s As String 
		  
		  Dim hours As Integer
		  Dim mins As Integer
		  Dim secs As Double 
		  
		  Dim gmtOffsetInSeconds As Double = d.GMTOffset * 3600
		  
		  hours = gmtOffsetInSeconds / 3600
		  mins = (gmtOffsetInSeconds - (hours * 3600)) / 60
		  secs = gmtOffsetInSeconds - (hours * 3600) - (mins * 60)
		  
		  hours = Abs(hours)
		  mins = Abs(mins)
		  
		  s = s + d.SQLDateTime
		  s = s +  " " + If(d.GMTOffset < 0, "-" , "+") + Format(hours,"00") + ":" + Format(mins,"00") + ":" + Format(secs,"00.00")
		  
		  Return s
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ToISO8601String(d as datetime) As string
		  // formats a date as yyyy-MM-DD HH:MM:SS [+/-]hh:mm:ss.sss
		  // hh is HOURS offset from GMT
		  // mm is minutes offset from GMT
		  
		  Dim s As String 
		  
		  Dim hours As Integer
		  Dim mins As Integer
		  Dim secs As Double 
		  
		  Dim gmtOffsetInSeconds As Double = d.Timezone.SecondsFromGMT
		  
		  hours = gmtOffsetInSeconds / 3600
		  mins = (gmtOffsetInSeconds - (hours * 3600)) / 60
		  secs = gmtOffsetInSeconds - (hours * 3600) - (mins * 60)
		  
		  hours = Abs(hours)
		  mins = Abs(mins)
		  
		  s = s + d.SQLDateTime
		  s = s +  " " + If(d.Timezone.SecondsFromGMT < 0, "-" , "+") + hours.ToString(Nil,"00") + ":" + mins.ToString(Nil,"00") + ":" + secs.ToString(Nil,"00.00")
		  
		  Return s
		  
		  
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mConnected
			End Get
		#tag EndGetter
		IsConnected As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h1
		Protected mConnected As boolean
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mDatabase As Database
	#tag EndProperty


	#tag ViewBehavior
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
			Name="IsConnected"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
