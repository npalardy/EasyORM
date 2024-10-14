#tag Class
Protected Class MyCustomTable
Inherits BaseTable
	#tag Method, Flags = &h0
		Sub Constructor()
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		DateColumn As Date
	#tag EndProperty

	#tag Property, Flags = &h0
		DateTimeColumn As DateTime
	#tag EndProperty

	#tag Property, Flags = &h21
		Private Untitled As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		Attributes( PrimaryKey, AutoIncrement, Unique ) Untitled1 As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		Untitled2 As Integer
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
			Name="Untitled1"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
