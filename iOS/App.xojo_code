#tag Class
Protected Class App
Inherits MobileApplication
	#tag CompatibilityFlags = TargetIOS
	#tag Event
		Sub Opening()
		  Const kUseSqlite = True
		  Const kUseMySQL = False
		  
		  Dim ormDB As ORMDatabase
		  
		  #If kUseSqlite Then
		    ormDB = New SQLIteORMDatabase
		    // NOT setting SQLIteORMDatabase(ormDB).DBPath makes this connect to an in memory db !
		    SQLIteORMDatabase(ormDB).DBPath = "easyORM Sample DB.sqlite" // makes this connect to a disk based db
		  #EndIf
		  
		  #If kUseMySQL Then
		    ormDB = New MySQLORMDatabase
		    MySQLORMDatabase(ormDB).Host = "127.0.0.1" 
		    MySQLORMDatabase(ormDB).Port = 3306
		    MySQLORMDatabase(ormDB).DatabaseName = "track_fd_data_norm"
		    MySQLORMDatabase(ormDB).Username = "root" 
		    MySQLORMDatabase(ormDB).Password = ""
		  #EndIf
		  
		  ormDB.Connect
		  
		  If ormDB.IsConnected = False Then
		    Break
		    Return
		  End If
		  
		  Dim tinfo As Introspection.TypeInfo = GetTypeInfo( MyCustomTable )
		  
		  // drop the table IF it exists !
		  ormDB.DeleteTable( tInfo )
		  
		  // get the ORM to run a "create table if not exists" statement
		  // <<<<<<<<<< really  want to just write ORMDatabase.CreateTable( CustomBaseTable ) but ...... Xojo cant do that
		  ormDB.CreateTable( tInfo )
		  
		  // <<<<<<<<<< 
		  // INSERTS
		  Dim toInsert123 As New MyCustomTable
		  toInsert123.Untitled1 = 123
		  toInsert123.Untitled2 = 123
		  #If TargetIOS = False 
		    toInsert123.DateColumn = New date(1986,02,05)
		  #EndIf
		  toInsert123.DateTimeColumn = New dateTime(2006,05,02)
		  ormDB.Insert( toInsert123 )
		  
		  Dim toInsert1 As New MyCustomTable
		  toInsert1.Untitled1 = 1
		  toInsert123.Untitled2 = 123
		  #If TargetIOS = False 
		    toInsert1.DateColumn = New date(1986,02,05,1,2,3,-7.25)
		  #EndIf
		  toInsert1.DateTimeColumn = New dateTime(2006,05,02,1,2,3,0, New TimeZone( 3500 ) )
		  ormDB.Insert( toInsert1 )
		  
		  Dim toInsert2 As New MyCustomTable
		  toInsert2.Untitled1 = 2
		  toInsert123.Untitled2 = 123
		  ormDB.Insert( toInsert2 )
		  
		  Dim toInsert3 As New MyCustomTable
		  toInsert3.Untitled1 = 3
		  toInsert123.Untitled2 = 123
		  ormDB.Insert( toInsert3 )
		  
		  Dim toInsert4 As New MyCustomTable
		  toInsert4.Untitled1 = 321
		  toInsert123.Untitled2 = 123
		  ormDB.Insert( toInsert4 )
		  
		  Dim toInsert5 As New MyCustomTable
		  toInsert5.Untitled1 = 231
		  toInsert123.Untitled2 = 123
		  ormDB.Insert( toInsert5 )
		  
		  // <<<<<<<<<< 
		  // FIND using different mechanisms
		  If True Then
		    Try
		      Dim tmp As BaseTable = ormDB.First( tInfo ) // find the first row in the table
		      Dim found As MyCustomTable = MyCustomTable(tmp) // since there are no true generics !
		      If found.Untitled1 = 1 Then
		        
		        If found.Untitled1 <> toinsert1.Untitled1 Then
		          Break
		        End If
		        
		        #If TargetIOS = False 
		          If found.DateColumn.SQLDateTime <> toinsert1.DateColumn.SQLDateTime Then
		            Break
		          End If
		        #EndIf
		        
		        #If kUseMySQL Or TargetIOS Then
		          // mysql date times do NOT store GMT OFfsets so DO NOT rely on them !
		        #Else
		          If found.DateColumn.GMTOffset <> toinsert1.DateColumn.GMTOffset Then
		            Break
		          End If
		        #EndIf
		        
		        If found.DateTimeColumn.SQLDateTime <> toinsert1.DateTimeColumn.SQLDateTime Then
		          Break
		        End If
		        #If kUseMySQL Or TargetIOS Then
		          // mysql date times do NOT store GMT OFfsets so DO NOT rely on them !
		        #Else
		          If found.DateTimeColumn.Timezone.SecondsFromGMT <> toinsert1.DateTimeColumn.Timezone.SecondsFromGMT Then
		            Break
		          End If
		        #EndIf
		        
		      End If
		    Catch dbx As DatabaseException
		      Break
		    End Try
		    
		  End If
		  
		  If True Then
		    Try
		      Dim tmp As BaseTable = ormDB.First( tInfo, "Untitled1 = 123" ) // find the first row in the table that matches
		      Dim found As MyCustomTable = MyCustomTable(tmp)
		      If found.Untitled1 = 123 Then
		        If found.Untitled1 <> toinsert123.Untitled1 Then
		          Break
		        End If
		        #If TargetIOS = False Then
		          If found.DateColumn.SQLDateTime <> toinsert123.DateColumn.SQLDateTime Then
		            Break
		          End If
		        #EndIf
		        #If kUseMySQL Or TargetIOS Then
		          // mysql date times do NOT store GMT OFfsets so DO NOT rely on them !
		        #Else
		          If found.DateColumn.GMTOffset <> toinsert123.DateColumn.GMTOffset Then
		            Break
		          End If
		        #EndIf
		        If found.DateTimeColumn.SQLDateTime <> toinsert123.DateTimeColumn.SQLDateTime Then
		          Break
		        End If
		        #If kUseMySQL Then
		          // mysql date times do NOT store GMT OFfsets so DO NOT rely on them !
		        #Else
		          If found.DateTimeColumn.Timezone.SecondsFromGMT <> toinsert123.DateTimeColumn.Timezone.SecondsFromGMT Then
		            Break
		          End If
		        #EndIf
		      End If
		      
		      
		    Catch dbx As DatabaseException
		      Break
		    End Try
		  End If
		  
		  If True Then
		    Try
		      Dim tmp As BaseTable = ormDB.Last( tInfo ) // find the LAST row in the table 
		      Dim found As MyCustomTable = MyCustomTable(tmp)
		      If 1 = 2 Then
		        Break
		      End If
		      
		    Catch dbx As DatabaseException
		      Break
		    End Try
		  End If
		  
		  If True Then
		    Try
		      Dim tmp As BaseTable = ormDB.Last( tInfo, "Untitled1 = 123" ) // find the LAST row in the table that matches
		      Dim found As MyCustomTable = MyCustomTable(tmp)
		      If 1 = 2 Then
		        Break
		      End If
		    Catch dbx As DatabaseException
		      Break
		    End Try
		  End If
		  
		  If True Then
		    Try
		      Dim tmp As BaseTable = ormDB.Last( tInfo, "Untitled2 = 123" ) // find the LAST row in the table that matches
		      Dim found As MyCustomTable = MyCustomTable(tmp)
		      If 1 = 2 Then
		        Break
		      End If
		    Catch dbx As DatabaseException
		      Break
		    End Try
		  End If
		  
		  
		  If True Then
		    Try
		      Dim tmp() As BaseTable = ormDB.Find( tInfo ) // find ALL rows in the table 
		      For Each r As BaseTable In tmp
		        Dim found As MyCustomTable = MyCustomTable(r)
		      Next
		      If 1 = 2 Then
		        Break
		      End If
		    Catch dbx As DatabaseException
		      Break
		    End Try
		  End If
		  
		  If True Then
		    Try
		      Dim tmp() As BaseTable = ormDB.Find( tInfo, "Untitled1 = 123" ) // find ALL rows in the table that match
		      For Each r As BaseTable In tmp
		        Dim found As MyCustomTable = MyCustomTable(r)
		      Next
		      If 1 = 2 Then
		        Break
		      End If
		    Catch dbx As DatabaseException
		      Break
		    End Try
		  End If
		  
		  
		  If True Then
		    Try
		      Dim tmp() As BaseTable = ormDB.Find( tInfo, "Untitled2 = 123" ) // find ALL rows in the table that match
		      For Each r As BaseTable In tmp
		        Dim found As MyCustomTable = MyCustomTable(r)
		      Next
		      If 1 = 2 Then
		        Break
		      End If
		    Catch dbx As DatabaseException
		      Break
		    End Try
		  End If
		  
		  
		  // <<<<<<<<<< 
		  // deletion using different mechanisms
		  If True Then
		    Try
		      Dim tmp As BaseTable = ormDB.First( tInfo, "Untitled1 = 123" ) // find the first row in the table that matches
		      Dim found As MyCustomTable = MyCustomTable(tmp)
		      If found <> Nil Then
		        ormDB.Delete( found ) // delete a specific row using an instance (uses the Primary Key)
		        Break
		      End If
		    Catch dbx As DatabaseException
		      Break
		    End Try
		  End If
		  
		  If True Then
		    Try
		      ormDB.Delete(  tInfo, "Untitled1 = 123" ) // delete rows from a table using a criteria string 
		      Break
		    Catch dbx As DatabaseException
		      Break
		    End Try
		  End If
		End Sub
	#tag EndEvent


End Class
#tag EndClass
