-- Rules: Runtime typechecker

--[[
	MIT License

	Copyright (c) 2025 daily

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
--]]

--!strict
--!optimize 2
--!native

type RuleValidator = (Value: unknown) -> (boolean, string?)
type VarargRuleValidator = (...unknown) -> (boolean, string?)

type Constructor<T> = (Negated: boolean) -> T

local Constructors = {}
local Not = {}
local Rules = {}

do
	local function CreateHook(Negated: boolean)
		return function(Table: any, Index: string?): any
			if Index == "Not" then
				if Table == Rules then
					return Not
				end

				return Rules
			end

			local Constructor = rawget(Constructors, Index)
			if not Constructor then
				error(`No constructor for {Index} exists`, 2)
			end

			local Result = Constructor(Negated)
			if type(Result) == "function" then
				rawset(Table, Index, Result)
			end

			return Result
		end
	end

	Rules.Not = (Not :: any) :: typeof(Rules)

	setmetatable(Not, { __index = CreateHook(true) })
	setmetatable(Rules, { __index = CreateHook(false) })
end

do -- Basic
	do -- Void
		Constructors.void = function(Negated: boolean)
			local Message = if Negated then "Value is void" else "Value isn't void"
			local Expected = not Negated

			return function(...: unknown)
				local Success = select("#", ...) == 0

				if Success == Expected then
					return true
				end

				return false, Message
			end
		end
		Constructors.Void = Constructors.void

		Rules.void = (nil :: any) :: RuleValidator
		Rules.Void = (nil :: any) :: typeof(Rules.void)
	end

	do -- None
		Constructors.none = function(Negated: boolean)
			local Message = if Negated then "Value is nil" else "Value isn't nil"
			local Expected = not Negated

			return function(Value: unknown)
				local Success = Value == nil

				if Success == Expected then
					return true
				end

				return false, Message
			end
		end
		Constructors.None = Constructors.none

		Rules.none = (nil :: any) :: RuleValidator
		Rules.None = (nil :: any) :: typeof(Rules.none)
	end

	do -- Optional
		Constructors.optional = function(Negated: boolean)
			if Negated then
				error("Rules.optional can't be negated", 2)
			end

			return function(Validator: RuleValidator)
				return function(Value: unknown)
					if Value == nil then
						return true, ""
					end

					return Validator(Value)
				end :: RuleValidator
			end
		end
		Constructors.Optional = Constructors.optional

		Rules.optional = (nil :: any) :: (Validator: RuleValidator) -> RuleValidator
		Rules.Optional = (nil :: any) :: typeof(Rules.optional)
	end

	do -- Literal
		Constructors.literal = function(Negated: boolean)
			local Expected = not Negated

			return function(ExpectedValue: any)
				local Message = if Negated then `Value cannot be {ExpectedValue}` else `Value is not {ExpectedValue}`

				return function(Value: unknown)
					local Success = Value == ExpectedValue

					if Success == Expected then
						return true
					end

					return false, Message
				end
			end
		end
		Constructors.Literal = Constructors.literal

		Rules.literal = (nil :: any) :: (Expected: any) -> RuleValidator
		Rules.Literal = (nil :: any) :: typeof(Rules.literal)
	end
end

do -- Primitives
	local function FromTypeConstructor(Type: string): Constructor<RuleValidator>
		return function(Negated: boolean)
			local Message = if Negated then `Value cannot be of type '{Type}'` else `Value isn't of type '{Type}'`
			local Expected = not Negated

			return function(Value: unknown)
				local Success = type(Value) == Type

				if Success == Expected then
					return true
				end

				return false, Message
			end
		end
	end

	Constructors.string = FromTypeConstructor("string")
	Constructors.String = Constructors.string

	Constructors.number = FromTypeConstructor("number")
	Constructors.Number = Constructors.number

	Constructors.table = FromTypeConstructor("table")
	Constructors.Table = Constructors.table

	Constructors.boolean = FromTypeConstructor("boolean")
	Constructors.Boolean = Constructors.boolean

	Constructors.thread = FromTypeConstructor("thread")
	Constructors.Thread = Constructors.thread

	Constructors.userdata = FromTypeConstructor("userdata")
	Constructors.Userdata = Constructors.userdata

	Constructors.buffer = FromTypeConstructor("buffer")
	Constructors.Buffer = Constructors.buffer

	Constructors.vector = FromTypeConstructor("vector")
	Constructors.Vector = Constructors.vector

	Constructors.callback = FromTypeConstructor("function")
	Constructors.Callback = Constructors.callback

	Rules.string = (nil :: any) :: RuleValidator
	Rules.String = (nil :: any) :: RuleValidator

	Rules.number = (nil :: any) :: RuleValidator
	Rules.Number = (nil :: any) :: RuleValidator

	Rules.table = (nil :: any) :: RuleValidator
	Rules.Table = (nil :: any) :: RuleValidator

	Rules.boolean = (nil :: any) :: RuleValidator
	Rules.Boolean = (nil :: any) :: RuleValidator

	Rules.thread = (nil :: any) :: RuleValidator
	Rules.Thread = (nil :: any) :: RuleValidator

	Rules.userdata = (nil :: any) :: RuleValidator
	Rules.Userdata = (nil :: any) :: RuleValidator

	Rules.buffer = (nil :: any) :: RuleValidator
	Rules.Buffer = (nil :: any) :: RuleValidator

	Rules.vector = (nil :: any) :: RuleValidator
	Rules.Vector = (nil :: any) :: RuleValidator

	Rules.callback = (nil :: any) :: RuleValidator
	Rules.Callback = (nil :: any) :: RuleValidator

	Constructors.real_number = function(Negated: boolean)
		if Negated then
			error("Rules.real_number can't be negated", 2)
		end

		return function(Value: unknown)
			if type(Value) ~= "number" then
				return false, "Value isn't of type 'number'"
			end

			if Value ~= Value then
				return false, "Value must not be NaN"
			end

			local Success = math.abs(Value :: number) ~= math.huge
			if Success then
				return true
			end

			return false, "Value cannot be infinite"
		end :: RuleValidator
	end
	Constructors.realnumber = Constructors.real_number
	Constructors.RealNumber = Constructors.real_number

	Rules.real_number = (nil :: any) :: RuleValidator
	Rules.realnumber = (nil :: any) :: RuleValidator
	Rules.RealNumber = (nil :: any) :: RuleValidator

	Constructors.strict_number = function(Negated: boolean)
		if Negated then
			error("Rules.strict_number can't be negated", 2)
		end

		return function(Value: unknown)
			if type(Value) ~= "number" then
				return false, "Value isn't of type 'number'"
			end

			local Success = Value == Value
			if Success then
				return true
			end

			return false, "Value cannot be NaN"
		end :: RuleValidator
	end
	Constructors.strictnumber = Constructors.strict_number
	Constructors.StrictNumber = Constructors.strict_number

	Rules.strict_number = (nil :: any) :: RuleValidator
	Rules.strictnumber = (nil :: any) :: RuleValidator
	Rules.StrictNumber = (nil :: any) :: RuleValidator
end

do -- Classes
	local function FromClassConstructor(Type: string): Constructor<RuleValidator>
		return function(Negated: boolean)
			local Message = if Negated then `Value cannot be of type '{Type}'` else `Value isn't of type '{Type}'`
			local Expected = not Negated

			return function(Value: unknown)
				local Success = typeof(Value) == Type

				if Success == Expected then
					return true
				end

				return false, Message
			end
		end
	end

	Constructors.axes = FromClassConstructor("Axes")
	Constructors.Axes = Constructors.axes
	Constructors.brick_color = FromClassConstructor("BrickColor")
	Constructors.brickcolor = Constructors.brick_color
	Constructors.BrickColor = Constructors.brick_color
	Constructors.catalog_search_params = FromClassConstructor("CatalogSearchParams")
	Constructors.catalogsearchparams = Constructors.catalog_search_params
	Constructors.CatalogSearchParams = Constructors.catalog_search_params
	Constructors.cframe = FromClassConstructor("CFrame")
	Constructors.CFrame = Constructors.cframe
	Constructors.color3 = FromClassConstructor("Color3")
	Constructors.Color3 = Constructors.color3
	Constructors.color_sequence = FromClassConstructor("ColorSequence")
	Constructors.colorsequence = Constructors.color_sequence
	Constructors.ColorSequence = Constructors.color_sequence
	Constructors.color_sequence_keypoint = FromClassConstructor("ColorSequenceKeypoint")
	Constructors.colorsequencekeypoint = Constructors.color_sequence_keypoint
	Constructors.ColorSequenceKeypoint = Constructors.color_sequence_keypoint
	Constructors.date_time = FromClassConstructor("DateTime")
	Constructors.datetime = Constructors.date_time
	Constructors.DateTime = Constructors.date_time
	Constructors.dock_widget_plugin_gui_info = FromClassConstructor("DockWidgetPluginGuiInfo")
	Constructors.dockwidgetpluginguiinfo = Constructors.dock_widget_plugin_gui_info
	Constructors.DockWidgetPluginGuiInfo = Constructors.dock_widget_plugin_gui_info
	Constructors.faces = FromClassConstructor("Faces")
	Constructors.Faces = Constructors.faces
	Constructors.float_curve_key = FromClassConstructor("FloatCurveKey")
	Constructors.floatcurvekey = Constructors.float_curve_key
	Constructors.FloatCurveKey = Constructors.float_curve_key
	Constructors.font = FromClassConstructor("Font")
	Constructors.Font = Constructors.font
	Constructors.instance = FromClassConstructor("Instance")
	Constructors.Instance = Constructors.instance
	Constructors.number_range = FromClassConstructor("NumberRange")
	Constructors.numberrange = Constructors.number_range
	Constructors.NumberRange = Constructors.number_range
	Constructors.number_sequence = FromClassConstructor("NumberSequence")
	Constructors.numbersequence = Constructors.number_sequence
	Constructors.NumberSequence = Constructors.number_sequence
	Constructors.number_sequence_keypoint = FromClassConstructor("NumberSequenceKeypoint")
	Constructors.numbersequencekeypoint = Constructors.number_sequence_keypoint
	Constructors.NumberSequenceKeypoint = Constructors.number_sequence_keypoint
	Constructors.overlap_params = FromClassConstructor("OverlapParams")
	Constructors.overlapparams = Constructors.overlap_params
	Constructors.OverlapParams = Constructors.overlap_params
	Constructors.path_waypoint = FromClassConstructor("PathWaypoint")
	Constructors.pathwaypoint = Constructors.path_waypoint
	Constructors.PathWaypoint = Constructors.path_waypoint
	Constructors.physical_properties = FromClassConstructor("PhysicalProperties")
	Constructors.physicalproperties = Constructors.physical_properties
	Constructors.PhysicalProperties = Constructors.physical_properties
	Constructors.random = FromClassConstructor("Random")
	Constructors.Random = Constructors.random
	Constructors.ray = FromClassConstructor("Ray")
	Constructors.Ray = Constructors.ray
	Constructors.raycast_params = FromClassConstructor("RaycastParams")
	Constructors.raycastparams = Constructors.raycast_params
	Constructors.RaycastParams = Constructors.raycast_params
	Constructors.raycast_result = FromClassConstructor("RaycastResult")
	Constructors.raycastresult = Constructors.raycast_result
	Constructors.RaycastResult = Constructors.raycast_result
	Constructors.rbx_script_connection = FromClassConstructor("RBXScriptConnection")
	Constructors.rbxscriptconnection = Constructors.rbx_script_connection
	Constructors.RBXScriptConnection = Constructors.rbx_script_connection
	Constructors.rbx_script_signal = FromClassConstructor("RBXScriptSignal")
	Constructors.rbxscriptsignal = Constructors.rbx_script_signal
	Constructors.RBXScriptSignal = Constructors.rbx_script_signal
	Constructors.rect = FromClassConstructor("Rect")
	Constructors.Rect = Constructors.rect
	Constructors.region3 = FromClassConstructor("Region3")
	Constructors.Region3 = Constructors.region3
	Constructors.region3int16 = FromClassConstructor("Region3int16")
	Constructors.Region3int16 = Constructors.region3int16
	Constructors.tween_info = FromClassConstructor("TweenInfo")
	Constructors.tweeninfo = Constructors.tween_info
	Constructors.TweenInfo = Constructors.tween_info
	Constructors.udim = FromClassConstructor("UDim")
	Constructors.UDim = Constructors.udim
	Constructors.udim2 = FromClassConstructor("UDim2")
	Constructors.UDim2 = Constructors.udim2
	Constructors.vector2 = FromClassConstructor("Vector2")
	Constructors.Vector2 = Constructors.vector2
	Constructors.vector2int16 = FromClassConstructor("Vector2int16")
	Constructors.Vector2int16 = Constructors.vector2int16
	Constructors.vector3 = FromClassConstructor("Vector3")
	Constructors.Vector3 = Constructors.vector3
	Constructors.vector3int16 = FromClassConstructor("Vector3int16")
	Constructors.Vector3int16 = Constructors.vector3int16

	Rules.axes = (nil :: any) :: RuleValidator
	Rules.Axes = (nil :: any) :: RuleValidator

	Rules.brick_color = (nil :: any) :: RuleValidator
	Rules.brickcolor = (nil :: any) :: RuleValidator
	Rules.BrickColor = (nil :: any) :: RuleValidator

	Rules.catalog_search_params = (nil :: any) :: RuleValidator
	Rules.catalogsearchparams = (nil :: any) :: RuleValidator
	Rules.CatalogSearchParams = (nil :: any) :: RuleValidator

	Rules.cframe = (nil :: any) :: RuleValidator
	Rules.CFrame = (nil :: any) :: RuleValidator

	Rules.color3 = (nil :: any) :: RuleValidator
	Rules.Color3 = (nil :: any) :: RuleValidator

	Rules.color_sequence = (nil :: any) :: RuleValidator
	Rules.colorsequence = (nil :: any) :: RuleValidator
	Rules.ColorSequence = (nil :: any) :: RuleValidator

	Rules.color_sequence_keypoint = (nil :: any) :: RuleValidator
	Rules.colorsequencekeypoint = (nil :: any) :: RuleValidator
	Rules.ColorSequenceKeypoint = (nil :: any) :: RuleValidator

	Rules.date_time = (nil :: any) :: RuleValidator
	Rules.datetime = (nil :: any) :: RuleValidator
	Rules.DateTime = (nil :: any) :: RuleValidator

	Rules.dock_widget_plugin_gui_info = (nil :: any) :: RuleValidator
	Rules.dockwidgetpluginguiinfo = (nil :: any) :: RuleValidator
	Rules.DockWidgetPluginGuiInfo = (nil :: any) :: RuleValidator

	Rules.faces = (nil :: any) :: RuleValidator
	Rules.Faces = (nil :: any) :: RuleValidator

	Rules.float_curve_key = (nil :: any) :: RuleValidator
	Rules.floatcurvekey = (nil :: any) :: RuleValidator
	Rules.FloatCurveKey = (nil :: any) :: RuleValidator

	Rules.font = (nil :: any) :: RuleValidator
	Rules.Font = (nil :: any) :: RuleValidator

	Rules.instance = (nil :: any) :: RuleValidator
	Rules.Instance = (nil :: any) :: RuleValidator

	Rules.number_range = (nil :: any) :: RuleValidator
	Rules.numberrange = (nil :: any) :: RuleValidator
	Rules.NumberRange = (nil :: any) :: RuleValidator

	Rules.number_sequence = (nil :: any) :: RuleValidator
	Rules.numbersequence = (nil :: any) :: RuleValidator
	Rules.NumberSequence = (nil :: any) :: RuleValidator

	Rules.number_sequence_keypoint = (nil :: any) :: RuleValidator
	Rules.numbersequencekeypoint = (nil :: any) :: RuleValidator
	Rules.NumberSequenceKeypoint = (nil :: any) :: RuleValidator

	Rules.overlap_params = (nil :: any) :: RuleValidator
	Rules.overlapparams = (nil :: any) :: RuleValidator
	Rules.OverlapParams = (nil :: any) :: RuleValidator

	Rules.path_waypoint = (nil :: any) :: RuleValidator
	Rules.pathwaypoint = (nil :: any) :: RuleValidator
	Rules.PathWaypoint = (nil :: any) :: RuleValidator

	Rules.physical_properties = (nil :: any) :: RuleValidator
	Rules.physicalproperties = (nil :: any) :: RuleValidator
	Rules.PhysicalProperties = (nil :: any) :: RuleValidator

	Rules.random = (nil :: any) :: RuleValidator
	Rules.Random = (nil :: any) :: RuleValidator

	Rules.ray = (nil :: any) :: RuleValidator
	Rules.Ray = (nil :: any) :: RuleValidator

	Rules.raycast_params = (nil :: any) :: RuleValidator
	Rules.raycastparams = (nil :: any) :: RuleValidator
	Rules.RaycastParams = (nil :: any) :: RuleValidator

	Rules.raycast_result = (nil :: any) :: RuleValidator
	Rules.raycastresult = (nil :: any) :: RuleValidator
	Rules.RaycastResult = (nil :: any) :: RuleValidator

	Rules.rbx_script_connection = (nil :: any) :: RuleValidator
	Rules.rbxscriptconnection = (nil :: any) :: RuleValidator
	Rules.RBXScriptConnection = (nil :: any) :: RuleValidator

	Rules.rbx_script_signal = (nil :: any) :: RuleValidator
	Rules.rbxscriptsignal = (nil :: any) :: RuleValidator
	Rules.RBXScriptSignal = (nil :: any) :: RuleValidator

	Rules.rect = (nil :: any) :: RuleValidator
	Rules.Rect = (nil :: any) :: RuleValidator

	Rules.region3 = (nil :: any) :: RuleValidator
	Rules.Region3 = (nil :: any) :: RuleValidator

	Rules.region3int16 = (nil :: any) :: RuleValidator
	Rules.Region3int16 = (nil :: any) :: RuleValidator

	Rules.tween_info = (nil :: any) :: RuleValidator
	Rules.tweeninfo = (nil :: any) :: RuleValidator
	Rules.TweenInfo = (nil :: any) :: RuleValidator

	Rules.udim = (nil :: any) :: RuleValidator
	Rules.UDim = (nil :: any) :: RuleValidator

	Rules.udim2 = (nil :: any) :: RuleValidator
	Rules.UDim2 = (nil :: any) :: RuleValidator

	Rules.vector2 = (nil :: any) :: RuleValidator
	Rules.Vector2 = (nil :: any) :: RuleValidator

	Rules.vector2int16 = (nil :: any) :: RuleValidator
	Rules.Vector2int16 = (nil :: any) :: RuleValidator

	Rules.vector3 = (nil :: any) :: RuleValidator
	Rules.Vector3 = (nil :: any) :: RuleValidator

	Rules.vector3int16 = (nil :: any) :: RuleValidator
	Rules.Vector3int16 = (nil :: any) :: RuleValidator
end

do -- Enums
	Constructors.enum = function(Negated: boolean)
		local Message = if Negated then "Value cannot be an Enum" else "Value is not an Enum"
		local Expected = not Negated

		return function(Value: unknown)
			local Success = typeof(Value) == "Enum"
			if Success == Expected then
				return true
			end

			return false, Message
		end
	end
	Constructors.Enum = Constructors.enum

	Rules.enum = (nil :: any) :: RuleValidator
	Rules.Enum = (nil :: any) :: RuleValidator

	Constructors.enum_item = function(Negated: boolean)
		local Message = if Negated then "Value cannot be an Enum" else "Value is not an Enum"
		local Expected = not Negated

		return function(Value: unknown)
			local Success = typeof(Value) == "EnumItem"
			if Success == Expected then
				return true
			end

			return false, Message
		end
	end
	Constructors.enumitem = Constructors.enum_item
	Constructors.EnumItem = Constructors.enum_item

	Rules.enum_item = (nil :: any) :: RuleValidator
	Rules.enumitem = (nil :: any) :: RuleValidator
	Rules.EnumItem = (nil :: any) :: RuleValidator

	Constructors.from_enum = function(Negated: boolean)
		if Negated then
			error("Rules.from_enum can't be negated", 2)
		end

		return function(EnumType: Enum): RuleValidator
			return function(Value: unknown)
				if typeof(Value) ~= "EnumItem" then
					return false, "Value isn't of type 'EnumItem'"
				end

				local Success = (Value :: EnumItem).EnumType == EnumType
				return Success, `Value is not of enum type '{EnumType}'`
			end
		end
	end
	Constructors.fromenum = Constructors.from_enum
	Constructors.FromEnum = Constructors.from_enum

	Rules.from_enum = (nil :: any) :: RuleValidator
	Rules.fromenum = (nil :: any) :: RuleValidator
	Rules.FromEnum = (nil :: any) :: RuleValidator
end

do -- Type Variants
	do -- Array
		Constructors.array = function(Negated: boolean)
			local Message = if Negated then "Value cannot be an array" else "Value is not an array"
			local Expected = not Negated

			return function(Value: unknown)
				if type(Value) ~= "table" then
					return false, "Value isn't of type 'table'"
				end

				local ValueCasted = Value :: {}
				local Key = next(ValueCasted, table.maxn(ValueCasted))

				local Success = Key == nil
				if Success == Expected then
					return true
				end

				return false, Message
			end :: RuleValidator
		end
		Constructors.Array = Constructors.array

		Rules.array = (nil :: any) :: RuleValidator
		Rules.Array = (nil :: any) :: RuleValidator

		Constructors.strict_array = function(Negated: boolean)
			if Negated then
				error("Rules.strict_array can't be negated", 2)
			end

			return function(Value: unknown)
				if type(Value) ~= "table" then
					return false, "Value isn't of type 'table'"
				end

				local ValueCasted = Value :: any

				local Elements = table.maxn(ValueCasted)
				if Elements == 0 then
					if next(ValueCasted) ~= nil then
						return false, "Value is not an array"
					end

					return true
				end

				local Key = next(ValueCasted, Elements)
				if Key ~= nil then
					return false, "Value is not an array"
				end

				local CurrentKey: number?, KeyValue: any = next(ValueCasted)
				local LastKey: number? = nil

				while CurrentKey do
					if CurrentKey % 1 ~= 0 then
						return false, "Value must not have fractional indices"
					end

					if KeyValue == nil and CurrentKey ~= Elements then
						return false, "Value must not have nil values inbetween or at the start"
					end

					if LastKey ~= nil and CurrentKey ~= LastKey + 1 then
						return false, "Value must not have gaps in indices or negative indices"
					end

					LastKey = CurrentKey
					CurrentKey, KeyValue = next(ValueCasted, CurrentKey)
				end

				local FirstKey = next(ValueCasted)
				if FirstKey ~= 1 then
					return false, "Value must not have nil values inbetween or at the start"
				end

				return true
			end :: RuleValidator
		end
		Constructors.strictarray = Constructors.strict_array
		Constructors.StrictArray = Constructors.strict_array

		Rules.strict_array = (nil :: any) :: RuleValidator
		Rules.strictarray = (nil :: any) :: RuleValidator
		Rules.StrictArray = (nil :: any) :: RuleValidator
	end

	Constructors.frozen = function(Negated: boolean)
		local Message = if Negated then "Value cannot be frozen" else "Value is not frozen"
		local Expected = not Negated

		return function(Value: unknown)
			if type(Value) ~= "table" then
				return false, "Value isn't of type 'table'"
			end

			local Success = table.isfrozen(Value :: {})
			if Success == Expected then
				return true
			end

			return false, Message
		end :: RuleValidator
	end
	Constructors.Frozen = Constructors.frozen

	Rules.frozen = (nil :: any) :: RuleValidator
	Rules.Frozen = (nil :: any) :: RuleValidator
end

do -- Values
	do -- Instances
		local Vowels = { a = true, e = true, i = true, o = true, u = true }
		Constructors.class_name = function(Negated: boolean)
			local Expected = not Negated

			return function(Class: string): RuleValidator
				local Article = Vowels[Class:sub(1, 1):lower()] and "an" or "a"
				local Message = if Negated
					then `Value cannot be {Article} {Class}`
					else `Value is not {Article} {Class}`

				return function(Value: unknown)
					if typeof(Value) ~= "Instance" then
						return false, "Value isn't of type 'Instance'"
					end

					local Success = (Value :: Instance):IsA(Class)
					if Success == Expected then
						return true
					end

					return false, Message
				end :: RuleValidator
			end
		end
		Constructors.classname = Constructors.class_name
		Constructors.ClassName = Constructors.class_name

		Rules.class_name = (nil :: any) :: (Class: string) -> RuleValidator
		Rules.classname = (nil :: any) :: typeof(Rules.class_name)
		Rules.ClassName = (nil :: any) :: typeof(Rules.class_name)

		Constructors.descendant_of = function(Negated: boolean)
			local Expected = not Negated

			return function(Inst: Instance)
				local Message = if Negated
					then `Value cannot be a descendant of {Inst.Name}`
					else `Value is not a descendant of {Inst.Name}`

				return function(Value: unknown)
					if typeof(Value) ~= "Instance" then
						return false, "Value isn't of type 'Instance'"
					end

					if not Inst or Inst.Parent == nil then
						return false, "Object was destroyed or parented to nil"
					end

					local Success = (Value :: Instance):IsDescendantOf(Inst)
					if Success == Expected then
						return true
					end

					return false, Message
				end :: RuleValidator
			end
		end
		Constructors.descendantof = Constructors.descendant_of
		Constructors.DescendantOf = Constructors.descendant_of

		Rules.descendant_of = (nil :: any) :: (Inst: Instance) -> RuleValidator
		Rules.descendantof = (nil :: any) :: typeof(Rules.descendant_of)
		Rules.DescendantOf = (nil :: any) :: typeof(Rules.descendant_of)
	end

	do -- Table Entries
		local function Validate(
			Value: unknown,
			CheckValue: boolean,
			Validator: RuleValidator,
			TreatTablesAsValues: boolean?,
			Recursive: boolean?
		)
			if type(Value) ~= "table" then
				return false, "Value isn't of type 'table'"
			end

			local Seen = {}
			setmetatable(Seen, { __mode = "k" })

			local Success: boolean, Message: string = true, ""

			local function ValidateTable(Table: {}, Parent: { string })
				for Key, TableValue in Table do
					if not Success then
						break
					end

					if type(TableValue) == "table" then
						if Recursive == true and not Seen[TableValue] and TreatTablesAsValues ~= true then
							Seen[TableValue] = true
							local NewParent = table.clone(Parent)
							table.insert(NewParent, Key :: string)
							ValidateTable(TableValue :: {}, NewParent)
						end

						if not TreatTablesAsValues then
							continue
						end
					end

					if not Success then
						break
					end

					local ThisSuccess, ThisMessage = Validator(if CheckValue then TableValue else Key)

					if not ThisSuccess then
						Success, Message =
							ThisSuccess,
							`{if #Parent > 0 then table.concat(Parent, ".") .. "." else ""}{Key}: {ThisMessage}`
						break
					end
				end
			end

			ValidateTable(Value :: {}, {})

			if Success then
				return true
			end

			return false, Message
		end

		Constructors.values = function(Negated: boolean)
			local _Expected = Negated

			return function(Validator: RuleValidator, TreatTablesAsValues: boolean?, Recursive: boolean?): RuleValidator
				return function(Value: unknown)
					return Validate(Value, true, Validator, TreatTablesAsValues, Recursive)
				end
			end
		end
		Constructors.Values = Constructors.values

		Rules.values = (
			nil :: any
		) :: (Validator: RuleValidator, TreatTablesAsValues: boolean?, Recursive: boolean?) -> RuleValidator
		Rules.Values = (nil :: any) :: typeof(Rules.values)

		Constructors.keys = function(Negated: boolean)
			local _Expected = Negated

			return function(Validator: RuleValidator, Recursive: boolean?): RuleValidator
				return function(Value: unknown)
					return Validate(Value, true, Validator, false, Recursive)
				end
			end
		end
		Constructors.Keys = Constructors.keys

		Rules.keys = (nil :: any) :: (Validator: RuleValidator, Recursive: boolean?) -> RuleValidator
		Rules.Keys = (nil :: any) :: typeof(Rules.keys)
	end

	do -- Size
		Constructors.string_length = function(Negated: boolean)
			local Expected = not Negated

			return function(MaxLength: number, Exact: boolean?): RuleValidator
				local Message: string = nil

				if Exact == true then
					Message = if Negated
						then `Value is not {MaxLength} characters`
						else `Value cannot be {MaxLength} characters`
				else
					Message = if Negated
						then `Value is shorter than {MaxLength} characters`
						else `Value is longer than {MaxLength} characters`
				end

				return function(Value: unknown)
					if type(Value) ~= "string" then
						return false, "Value isn't of type 'string'"
					end

					local Length = string.len(Value :: string)
					local Success = if Exact then Length == MaxLength else Length <= MaxLength
					if Success == Expected then
						return true
					end

					return false, Message
				end
			end
		end
		Constructors.stringlength = Constructors.string_length
		Constructors.StringLength = Constructors.string_length

		Rules.string_length = (nil :: any) :: (MaxLength: number, Exact: boolean?) -> RuleValidator
		Rules.stringlength = (nil :: any) :: typeof(Rules.string_length)
		Rules.StringLength = (nil :: any) :: typeof(Rules.string_length)

		Constructors.buffer_size = function(Negated: boolean)
			local Expected = not Negated

			return function(MaxLength: number, Exact: boolean?): RuleValidator
				local Message: string = nil

				if Exact == true then
					Message = if Negated then `Value is not {MaxLength} bytes` else `Value cannot be {MaxLength} bytes`
				else
					Message = if Negated
						then `Value is shorter than {MaxLength} bytes`
						else `Value is longer than {MaxLength} bytes`
				end

				return function(Value: unknown)
					if type(Value) ~= "buffer" then
						return false, "Value isn't of type 'buffer'"
					end

					local Length = buffer.len(Value :: buffer)
					local Success = if Exact then Length == MaxLength else Length <= MaxLength
					if Success == Expected then
						return true
					end

					return false, Message
				end
			end
		end
		Constructors.buffersize = Constructors.buffer_size
		Constructors.BufferSize = Constructors.buffer_size

		Rules.buffer_size = (nil :: any) :: (MaxLength: number, Exact: boolean?) -> RuleValidator
		Rules.buffersize = (nil :: any) :: typeof(Rules.buffer_size)
		Rules.BufferSize = (nil :: any) :: typeof(Rules.buffer_size)

		Constructors.table_size = function(Negated: boolean)
			local Expected = not Negated

			return function(MaxSize: number, Exact: boolean?): RuleValidator
				local Message: string = nil

				if Exact == true then
					Message = if Negated
						then `Value doesn't have {MaxSize} elements`
						else `Value cannot have {MaxSize} elements`
				else
					Message = if Negated
						then `Value has less than {MaxSize} elements`
						else `Value has more than {MaxSize} elements`
				end

				return function(Value: unknown)
					if type(Value) ~= "table" then
						return false, "Value isn't of type 'table'"
					end

					local Count = 0
					for _ in Value :: {} do
						Count += 1
					end

					local Success = if Exact then Count == MaxSize else Count <= MaxSize
					if Success == Expected then
						return true
					end

					return false, Message
				end
			end
		end
		Constructors.tablesize = Constructors.table_size
		Constructors.TableSize = Constructors.table_size

		Rules.table_size = (nil :: any) :: (MaxSize: number, Exact: boolean?) -> RuleValidator
		Rules.tablesize = (nil :: any) :: typeof(Rules.table_size)
		Rules.TableSize = (nil :: any) :: typeof(Rules.table_size)

		Constructors.array_size = function(Negated: boolean)
			local Expected = not Negated

			return function(MaxSize: number, Exact: boolean?): RuleValidator
				local Message: string = nil

				if Exact == true then
					Message = if Negated
						then `Value doesn't have {MaxSize} elements`
						else `Value cannot have {MaxSize} elements`
				else
					Message = if Negated
						then `Value has less than {MaxSize} elements`
						else `Value has more than {MaxSize} elements`
				end

				return function(Value: unknown)
					if type(Value) ~= "table" then
						return false, "Value isn't of type 'table'"
					end

					local Count = table.maxn(Value :: {})
					local Success = if Exact then Count == MaxSize else Count <= MaxSize
					if Success == Expected then
						return true
					end

					return false, Message
				end
			end
		end
		Constructors.arraysize = Constructors.array_size
		Constructors.ArraySize = Constructors.array_size

		Rules.array_size = (nil :: any) :: (MaxSize: number, Exact: boolean?) -> RuleValidator
		Rules.arraysize = (nil :: any) :: typeof(Rules.array_size)
		Rules.ArraySize = (nil :: any) :: typeof(Rules.array_size)
	end

	do -- Numbers
		Constructors.nan = function(Negated: boolean)
			local Message = if Negated then "Value cannot be NaN" else "Value must be NaN"
			local Expected = not Negated

			return function(Value: unknown)
				if type(Value) ~= "number" then
					return false, "Value isn't of type 'number'"
				end

				local Success = Value ~= Value
				if Success == Expected then
					return true
				end

				return false, Message
			end :: RuleValidator
		end
		Constructors.NaN = Constructors.nan

		Rules.nan = (nil :: any) :: RuleValidator
		Rules.NaN = (nil :: any) :: RuleValidator

		Constructors.infinite = function(Negated: boolean)
			local Message = if Negated then "Value cannot be NaN" else "Value must be NaN"
			local Expected = not Negated

			return function(Value: unknown)
				if type(Value) ~= "number" then
					return false, "Value isn't of type 'number'"
				end

				local Success = Value == math.huge
				if Success == Expected then
					return true
				end

				return false, Message
			end :: RuleValidator
		end

		Rules.infinite = (nil :: any) :: RuleValidator
		Rules.Infinite = (nil :: any) :: RuleValidator

		Constructors.integer = function(Negated: boolean)
			local Message = if Negated then "Value cannot be an integer" else "Value is not an integer"
			local Expected = not Negated

			return function(Value: unknown)
				local IsNumber, TypeError = Rules.strict_number(Value)
				if not IsNumber then
					return false, TypeError
				end

				if Rules.infinite(Value) then
					return false, "Value is infinite"
				end

				local _Integral, Fractional = math.modf(Value :: number)
				local Success = Fractional == 0
				if Success == Expected then
					return true
				end

				return false, Message
			end
		end
		Constructors.Integer = Constructors.integer

		Rules.integer = (nil :: any) :: RuleValidator
		Rules.Integer = (nil :: any) :: RuleValidator

		Constructors.positive_number = function(Negated: boolean)
			local Message = if Negated then "Value cannot be positive" else "Value is not positive"
			local Expected = not Negated

			return function(Value: unknown)
				local IsNumber, TypeError = Rules.strict_number(Value)
				if not IsNumber then
					return false, TypeError
				end

				local Success = (Value :: number) >= 0
				if Success == Expected then
					return true
				end

				return false, Message
			end
		end
		Constructors.positivenumber = Constructors.positive_number
		Constructors.PositiveNumber = Constructors.positive_number

		Rules.positive_number = (nil :: any) :: RuleValidator
		Rules.positivenumber = (nil :: any) :: RuleValidator
		Rules.PositiveNumber = (nil :: any) :: RuleValidator

		Constructors.negative_number = function(Negated: boolean)
			local Message = if Negated then "Value cannot be negative" else "Value is not negative"
			local Expected = not Negated

			return function(Value: unknown)
				local IsNumber, TypeError = Rules.strict_number(Value)
				if not IsNumber then
					return false, TypeError
				end

				local Success = (Value :: number) < 0
				if Success == Expected then
					return true
				end

				return false, Message
			end
		end
		Constructors.negativenumber = Constructors.negative_number
		Constructors.NegativeNumber = Constructors.negative_number

		Rules.negative_number = (nil :: any) :: RuleValidator
		Rules.negativenumber = (nil :: any) :: RuleValidator
		Rules.NegativeNumber = (nil :: any) :: RuleValidator

		Constructors.in_range_inclusive = function(Negated: boolean)
			local Expected = not Negated

			return function(Min: number, Max: number)
				local Message = if Negated
					then `Value must be outside the range of [{Min}..{Max}]`
					else `Value is outside the range of [{Min}..{Max}]`

				return function(Value: unknown)
					local IsNumber, TypeError = Rules.strict_number(Value)
					if not IsNumber then
						return false, TypeError
					end

					local Success = (Value :: number) >= Min and (Value :: number) <= Max
					if Success == Expected then
						return true
					end

					return false, Message
				end
			end
		end
		Constructors.inrangeinclusive = Constructors.in_range_inclusive
		Constructors.InRangeInclusive = Constructors.in_range_inclusive

		Rules.in_range_inclusive = (nil :: any) :: (Min: number, Max: number) -> RuleValidator
		Rules.inrangeinclusive = (nil :: any) :: typeof(Rules.in_range_inclusive)
		Rules.InRangeInclusive = (nil :: any) :: typeof(Rules.in_range_inclusive)

		Constructors.in_range_exclusive = function(Negated: boolean)
			local Expected = not Negated

			return function(Min: number, Max: number)
				local Message = if Negated
					then `Value must be outside the range of [{Min}..{Max})`
					else `Value is outside the range of [{Min}..{Max})`

				return function(Value: unknown)
					local IsNumber, TypeError = Rules.strict_number(Value)
					if not IsNumber then
						return false, TypeError
					end

					local Success = (Value :: number) >= Min and (Value :: number) < Max
					if Success == Expected then
						return true
					end

					return false, Message
				end
			end
		end
		Constructors.inrangeexclusive = Constructors.in_range_exclusive
		Constructors.InRangeExclusive = Constructors.in_range_exclusive

		Rules.in_range_exclusive = (nil :: any) :: (Min: number, Max: number) -> RuleValidator
		Rules.inrangeexclusive = (nil :: any) :: typeof(Rules.in_range_exclusive)
		Rules.InRangeExclusive = (nil :: any) :: typeof(Rules.in_range_exclusive)

		Constructors.minimum = function(Negated: boolean)
			return function(Min: number)
				return Constructors.in_range_inclusive(Negated)(Min, math.huge)
			end
		end
		Constructors.Minimum = Constructors.minimum

		Rules.minimum = (nil :: any) :: (Min: number) -> RuleValidator
		Rules.Minimum = (nil :: any) :: typeof(Rules.minimum)

		Constructors.maximum = function(Negated: boolean)
			return function(Max: number)
				return Constructors.in_range_inclusive(Negated)(-math.huge, Max)
			end
		end
		Constructors.Minimum = Constructors.maximum

		Rules.maximum = (nil :: any) :: (Max: number) -> RuleValidator
		Rules.Maximum = (nil :: any) :: typeof(Rules.maximum)

		Constructors.epsilon = function(Negated: boolean)
			local Expected = not Negated

			return function(Number: number, Epsilon: number)
				local Message = if Negated
					then `Value cannot be within {Epsilon} of {Number}`
					else `Value is not within {Epsilon} of {Number}`

				return function(Value: unknown)
					local IsNumber, TypeError = Rules.strict_number(Value)
					if not IsNumber then
						return false, TypeError
					end

					local Success = math.abs(Number - (Value :: number)) <= Epsilon
					if Success == Expected then
						return true
					end

					return false, Message
				end
			end
		end
		Constructors.Epsilon = Constructors.epsilon

		Rules.epsilon = (nil :: any) :: (Number: number, Epsilon: number) -> RuleValidator
		Rules.Epsilon = (nil :: any) :: typeof(Rules.epsilon)
	end

	do -- Values
		Constructors.valid_utf8 = function(Negated: boolean)
			local Expected = not Negated

			if Negated then
				error("Rules.valid_utf8 can't be negated", 2)
			end

			return function(Value: unknown)
				if type(Value) ~= "string" then
					return false, "Value isn't of type 'string'"
				end

				local Success = (utf8.len(Value :: string)) ~= nil
				if Success == Expected then
					return true
				end

				return false, "Value is not valid UTF8"
			end :: RuleValidator
		end
		Constructors.validutf8 = Constructors.valid_utf8
		Constructors.ValidUTF8 = Constructors.valid_utf8

		Rules.valid_utf8 = (nil :: any) :: RuleValidator
		Rules.validutf8 = (nil :: any) :: RuleValidator
		Rules.ValidUTF8 = (nil :: any) :: RuleValidator

		Constructors.finite_cframe = function(Negated: boolean)
			if Negated then
				error("Rules.finite_cframe can't be negated", 2)
			end

			return function(Value: unknown)
				if typeof(Value) ~= "CFrame" then
					return false, "Value isn't of type 'CFrame'"
				end

				for _, Axis in { "X", "Y", "Z" } do
					if not Rules.real_number((Value :: any)[Axis]) then
						return false, "CFrame is out of world bounds"
					end
				end

				local RotationMatrix = table.pack((Value :: CFrame):GetComponents())

				for Index = 4, RotationMatrix.n do
					local AxisValue = RotationMatrix[Index]

					if not Rules.real_number(AxisValue) then
						return false, "CFrame is out of world bounds"
					end
				end

				return true
			end :: RuleValidator
		end
		Constructors.finitecframe = Constructors.finite_cframe
		Constructors.FiniteCFrame = Constructors.finite_cframe

		Rules.finite_cframe = (nil :: any) :: RuleValidator
		Rules.finitecframe = (nil :: any) :: RuleValidator
		Rules.FiniteCFrame = (nil :: any) :: RuleValidator
	end

	do -- Structures
		Constructors.struct = function(Negated: boolean)
			if Negated then
				error("Rules.struct can't be negated", 2)
			end

			return function(TableStructure: { [any]: RuleValidator }, Strict: boolean?): RuleValidator
				return function(Value: unknown)
					if type(Value) ~= "table" then
						return false, "Value isn't of type 'table'"
					end

					if Strict == true then
						for Key, _ in Value :: {} do
							if TableStructure[Key] then
								continue
							end

							return false, `Value has unexpected field '{Key}'`
						end
					end

					for Key, RuleValidator in TableStructure do
						local TableValue = (Value :: {})[Key]

						if not TableValue and Strict == true then
							return false, `Value has missing field '{Key}'`
						end

						if type(RuleValidator) ~= "function" then
							return false, `{Key}: Expected rule, got {typeof(RuleValidator)}`
						end

						local Success, Message = RuleValidator(TableValue)

						if not Success then
							return false, `{Key}: {Message}`
						end
					end

					return true
				end
			end
		end
		Constructors.Struct = Constructors.struct

		Rules.struct = (nil :: any) :: (TableStructure: { [any]: RuleValidator }, Strict: boolean?) -> RuleValidator
		Rules.Struct = (nil :: any) :: typeof(Rules.struct)

		Constructors.strict_struct = function(Negated: boolean)
			if Negated then
				error("Rules.struct can't be negated", 2)
			end

			local StructConstructor = Constructors.strict(Negated)
			return function(TableStructure: { [any]: RuleValidator }): RuleValidator
				return StructConstructor(TableStructure, true)
			end
		end
		Constructors.strictstruct = Constructors.strict_struct
		Constructors.StrictStruct = Constructors.strict_struct

		Rules.strict_struct = (nil :: any) :: (TableStructure: { [any]: RuleValidator }) -> RuleValidator
		Rules.strictstruct = (nil :: any) :: typeof(Rules.strict_struct)
		Rules.StrictStruct = (nil :: any) :: typeof(Rules.strict_struct)
	end

	Constructors.depth = function(Negated: boolean)
		if Negated then
			error("Rules.depth can't be negated", 2)
		end

		return function(MaxDepth: number): RuleValidator
			return function(Value: unknown)
				if type(Value) ~= "table" then
					return false, "Value isn't of type 'table'"
				end

				local MaxDepthRecorded = 1
				local Seen = {}
				setmetatable(Seen, { __mode = "k" })

				local function Search(Table: {}, Depth: number)
					if Seen[Table] then
						return
					end

					if Depth > MaxDepthRecorded then
						MaxDepthRecorded = Depth
					end

					for Key, TableValue in Table do
						if type(Key) == "table" then
							Search(Key :: {}, Depth + 1)
						end

						if type(TableValue) == "table" then
							Search(TableValue :: {}, Depth + 1)
						end
					end
				end

				table.clear(Seen :: any)
				Search(Value :: {}, MaxDepthRecorded)

				local Success = MaxDepthRecorded <= MaxDepth
				if Success then
					return true
				end

				return false, `Value exceeds max depth of {MaxDepth}`
			end
		end
	end
	Constructors.Depth = Constructors.depth

	Rules.depth = (nil :: any) :: (MaxDepth: number) -> RuleValidator
	Rules.Depth = (nil :: any) :: typeof(Rules.depth)

	Constructors.match = function(Negated: boolean)
		local Expected = not Negated

		return function(Expression: string)
			local Message = if Negated
				then `Value must not match the regex expression '{Expression}'`
				else `Value doesn't match the regex expression '{Expression}'`

			return function(Value: unknown)
				if type(Value) ~= "string" then
					return false, "Value isn't of type 'string'"
				end

				local Success = string.match(Value :: string, Expression) ~= nil
				if Success == Expected then
					return true
				end

				return false, Message
			end :: RuleValidator
		end
	end
	Constructors.Match = Constructors.match

	Rules.match = (nil :: any) :: (Expression: string) -> RuleValidator
	Rules.Match = (nil :: any) :: typeof(Rules.match)
end

do -- Special
	Constructors.set = function(Negated: boolean)
		if Negated then
			error("Rules.set can't be negated", 2)
		end

		return function(...: RuleValidator): VarargRuleValidator
			local RuleSet = table.pack(...)
			local ExpectedArgumentCount = RuleSet.n

			return function(...: unknown)
				local Arguments = table.pack(...)
				local Count = Arguments.n

				if Count ~= ExpectedArgumentCount then
					local Error = if Count > ExpectedArgumentCount
						then `Got more than {ExpectedArgumentCount} arguments`
						else `Got less than {ExpectedArgumentCount} arguments`

					return false, Error
				end

				for Index = 1, Count do
					local Argument = Arguments[Index]
					local ArgumentValidator = RuleSet[Index]

					if type(ArgumentValidator) ~= "function" then
						return false, `#{Index}: Expected rule, got {typeof(ArgumentValidator)}`
					end

					local Success, Message = ArgumentValidator(Argument)

					if not Success then
						return false, `#{Index}: {Message}`
					end
				end

				return true
			end
		end
	end
	Constructors.Set = Constructors.set

	Rules.set = (nil :: any) :: (...RuleValidator) -> VarargRuleValidator
	Rules.Set = (nil :: any) :: typeof(Rules.set)

	Constructors.all = function(Negated: boolean)
		if Negated then
			error("Rules.all can't be negated", 2)
		end

		return function(...: RuleValidator): RuleValidator
			local RuleSet = { ... }

			return function(Value: unknown)
				for Index, RuleValidator in RuleSet do
					if type(RuleValidator) ~= "function" then
						return false, `#{Index}: Expected rule, got {typeof(RuleValidator)}`
					end

					local Success, Message = RuleValidator(Value)
					if not Success then
						return false, Message
					end
				end

				return true
			end
		end
	end
	Constructors.All = Constructors.all

	Rules.all = (nil :: any) :: (...RuleValidator) -> VarargRuleValidator
	Rules.All = (nil :: any) :: typeof(Rules.all)

	Constructors.var_arg = function(Negated: boolean)
		if Negated then
			error("Rules.var_arg can't be negated", 2)
		end

		return function(Validator: RuleValidator): VarargRuleValidator
			assert(Rules.callback(Validator))

			return function(...: unknown)
				local Arguments = table.pack(...)
				local Count = Arguments.n

				for Index = 1, Count do
					local Value = Arguments[Index]
					local Success, Message = Validator(Value)

					if not Success then
						return false, `#{Index}: {Message}`
					end
				end

				return true
			end
		end
	end
	Constructors.vararg = Constructors.var_arg
	Constructors.VarArg = Constructors.var_arg

	Rules.var_arg = (nil :: any) :: (Rule: RuleValidator) -> VarargRuleValidator
	Rules.vararg = (nil :: any) :: typeof(Rules.var_arg)
	Rules.VarArg = (nil :: any) :: typeof(Rules.var_arg)

	Constructors.union = function(Negated: boolean)
		if Negated then
			error("Rules.union can't be negated", 2)
		end

		return function(...: RuleValidator): RuleValidator
			local RuleSet = { ... }

			return function(Value: unknown)
				local FirstMessage: string = nil

				for Index, RuleValidator in RuleSet do
					if type(RuleValidator) ~= "function" then
						return false, `#{Index}: Provided validator is not a function`
					end

					local Success, Message = RuleValidator(Value)

					if not Success then
						if not FirstMessage and Message then
							FirstMessage = Message
						end
					else
						return true
					end
				end

				return false, FirstMessage
			end
		end
	end
	Constructors.Union = Constructors.union

	Rules.union = (nil :: any) :: (...RuleValidator) -> RuleValidator
	Rules.Union = (nil :: any) :: typeof(Rules.union)

	Constructors.strict = function(Negated: boolean)
		if Negated then
			error("Rules.strict can't be negated", 2)
		end

		return function(Validator: RuleValidator): (Value: unknown) -> boolean
			return function(Value: unknown)
				assert(Validator(Value))
				return true
			end
		end
	end
	Constructors.Strict = Constructors.strict

	Rules.strict = (nil :: any) :: (Rule: RuleValidator) -> (Value: unknown) -> boolean
	Rules.Strict = (nil :: any) :: typeof(Rules.strict)

	Rules.custom = function<T>(Constructor: Constructor<T>, Names: string | { string })
		if type(Names) == "string" then
			Constructors[Names] = Constructor
			return
		end

		for _, Name in Names :: { string } do
			Constructors[Name] = Constructor
		end
	end
	Rules.Custom = Rules.custom

	Rules.wrapped = function<Args..., Rets...>(Callback: (Args...) -> Rets..., Validator: RuleValidator): (Args...) -> Rets...
		return function(...: Args...)
			local Success, Message = Validator(...)

			if not Success then
				assert(false, Message)
			end

			return Callback(...)
		end
	end
	Rules.Wrapped = Rules.wrapped
end

return Rules
