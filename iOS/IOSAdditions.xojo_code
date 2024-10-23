#tag Module
Protected Module IOSAdditions
	#tag CompatibilityFlags = (TargetIOS and (Target64Bit))
	#tag Method, Flags = &h0
		Function Join(stringArray() as string, joinChar as String) As string
		  return string.FromArray( stringArray, joinChar )
		End Function
	#tag EndMethod


End Module
#tag EndModule
