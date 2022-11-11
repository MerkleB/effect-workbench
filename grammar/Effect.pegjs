{
	function concatStrings(stringArray){
    	var resultString = "";
        for(var i=0; i<stringArray.length; i++){
        	resultString = resultString + stringArray[i];
        }
        
        return resultString;
    }
    
    function convertNothing(possibleNothing, converted){
    	if(possibleNothing == ""){
        	return converted;
        }else{
        	return possibleNothing;
        }
    }
    
    function copyAction(actionToCopy){
    	var newAction = {
        	actor: actionToCopy.actor,
            mandatory:  actionToCopy.mandatory,
            action_type:  actionToCopy.action_type,
            location_from: {
            	owner: actionToCopy.location_from.owner,
                location: actionToCopy.location_from.location,
                object_type: actionToCopy.location_from.object_type,
                position: actionToCopy.location_from.position
            },
            location_to: {
            	owner: actionToCopy.location_to.owner === undefined ? "" : actionToCopy.location_to.owner,
                location: actionToCopy.location_to.location === undefined ? "" : actionToCopy.location_to.location,
                object_type: actionToCopy.location_to.object_type === undefined ? "" : actionToCopy.location_to.object_type,
                position: actionToCopy.location_to.position === undefined ? "" : actionToCopy.location_to.position
            }
        }
        return newAction;
    }

    function setMandatoryActorAndRecurrence(actions){
        var actor = actions[0].actor;
        var mandatory = actions[0].mandatory;
        var recurrence = actions[0].recurrence;

        for(var i=1; i<actions.length; i++){
            actions[i].actor = actor;
            actions[i].mandatory = mandatory;
            actions[i].recurrence = recurrence;
        }
    }
    
    function multiplyActions(actions){    	
        if(Array.isArray(actions[0])){
        	actions = actions[0];
        }
        setMandatoryActorAndRecurrence(actions);
    	var result = []
        var actionsSorted = sortActions(actions);
        var actionsWithOriginalIndex = {};
        var actionTypes = ["move", "select"];
        var lastResultCode = -1;
        var biggestIndexOfAllOriginalIndexes = 0;
        for(var h=0; h<actionTypes.length; h++){
            var actionType = actionTypes[h];
            for(var i=0; i<actionsSorted[actionType].length; i++){
                var currentAction = actionsSorted[actionType][i];
                var lengthOfCurrentOriginalIndex = 0
                if(actionsWithOriginalIndex[currentAction.original_index] !== undefined){
                    lengthOfCurrentOriginalIndex = actionsWithOriginalIndex[currentAction.original_index].length;
                }else{
                    actionsWithOriginalIndex[currentAction.original_index] = [];
                }
                if(currentAction.action.recurrence > 1){
                    for(var k=0; k<currentAction.action.recurrence; k++){
                        if(actionType == "select"){
                            var result_code = lastResultCode + 1
                            currentAction.action.location_from.position = "r"+result_code;
                            lastResultCode = result_code;
                        }
                        var copy = copyAction(currentAction.action);
                        copy = copyAction(currentAction.action); 
                        actionsWithOriginalIndex[currentAction.original_index][lengthOfCurrentOriginalIndex] = copy;
                        if(lengthOfCurrentOriginalIndex > biggestIndexOfAllOriginalIndexes){
                    		biggestIndexOfAllOriginalIndexes = lengthOfCurrentOriginalIndex;
                		}
                        lengthOfCurrentOriginalIndex++;
                    }
                }else{
                    if(actionType == "select"){
                        var result_code = lastResultCode + 1
                        currentAction.action.location_from.position = "r"+result_code;
                        lastResultCode = result_code;
                    }
                    var copy = copyAction(currentAction.action);
                    actionsWithOriginalIndex[currentAction.original_index][lengthOfCurrentOriginalIndex] = copy;
                    if(lengthOfCurrentOriginalIndex > biggestIndexOfAllOriginalIndexes){
                    	biggestIndexOfAllOriginalIndexes = lengthOfCurrentOriginalIndex;
                	}
                    lengthOfCurrentOriginalIndex++;
                }
            }
        }

        var result = [];
        var lastIndex = Object.keys(actionsWithOriginalIndex).length - 1;
        var newIndex = 0;
        for(var indexOfMultipliedInstances=0; indexOfMultipliedInstances <= biggestIndexOfAllOriginalIndexes; indexOfMultipliedInstances++)
        {
            for(var originalIndex = 0; originalIndex <= lastIndex; originalIndex++)
            {
                var aActionsAtOriginalIndex = actionsWithOriginalIndex[originalIndex];
                if(aActionsAtOriginalIndex.length - 1 >= indexOfMultipliedInstances)
                {
                    var action = aActionsAtOriginalIndex[indexOfMultipliedInstances];
                    var messages = [];
                    if(action.action_type == "move")
                    {
                        if(action.location_from.position !== undefined)
                        {
                            if(action.location_from.position === "")
                            {
                                if(newIndex-2 < 0  || result[newIndex-2] === undefined )
                                {
                                    messages[messages.length] = "Source Location of action index "+originalIndex+" could not be identified because there are no selections beforehand";
                                }
                                else
                                {
                                    var actionBeforeLastAction = result[newIndex-2];
                                    if(actionBeforeLastAction.action_type != "select")
                                    {
                                        messages[messages.length] = "Source Location of action index "+originalIndex+" could not be identified because the action before the last action is no selection";   
                                    }
                                    else
                                    {
                                        action.location_from.owner = actionBeforeLastAction.location_from.owner;
                                        action.location_from.location = actionBeforeLastAction.location_from.location;
                                        action.location_from.object_type = actionBeforeLastAction.location_from.object_type;
                                        action.location_from.position = "$"+actionBeforeLastAction.location_from.position;
                                    }                                 
                                }
                            }
                        }
                        if(action.location_to.position !== undefined)
                        {
                            if(action.location_to.position === "")
                            {
                                if(newIndex-1 < 0  || result[newIndex-1] === undefined )
                                {
                                    messages[messages.length] = "Target Location of action index "+originalIndex+" could not be identified because there are no selections beforehand";
                                }
                                else
                                {
                                    var lastAction = result[newIndex-1];
                                    if(lastAction.action_type != "select")
                                    {
                                        messages[messages.length] = "Target Location of action index "+originalIndex+" could not be identified because the last action is no selection";   
                                    }
                                    else
                                    {
                                        action.location_to.owner = lastAction.location_from.owner;
                                        action.location_to.location = lastAction.location_from.location;
                                        action.location_to.object_type = lastAction.location_from.object_type
                                        action.location_to.position = "$"+lastAction.location_from.position;
                                    }                                 
                                }
                            }
                        }
                    }
                    action.messages = messages;
                    result[newIndex] = action;
                    newIndex++;
                }
            }
        }
        return result;
    }
    
    function sortActions(actions){
    	if(!Array.isArray(actions)){
        	actions = [actions];
        }
        var actionsSorted = {move:[], select:[]};
        var moveIndex = 0, selectIndex = 0;
        for(var i=0; i<actions.length; i++){
        	var currentAction = actions[i]
            if(currentAction.action_type == "move"){
            	actionsSorted.move[moveIndex] = {action:currentAction, original_index:i};
                moveIndex++;
            }
            if(currentAction.action_type == "select"){
            	actionsSorted.select[selectIndex] = {action:currentAction, original_index:i};
                selectIndex++;
            }
        }
        return actionsSorted;
    }
    
    function concatArrays(array1,array2){
    	var result = [];
        var index = 0;
        for(var i=0; i<array1.length; i++){
        	result[index] = array1[i];
            index++;
        }
        for(var i=0; i<array2.length; i++){
        	result[index] = array2[i];
            index++;
        }
        return result;
    }

}

Effects = effects:Effect+ { return {Effects: effects }}

Effect = Whitespace / LineBreak / Nothing prerequisites:Prerequisites costs:(Costs / Nothing) actions:Actions "." (LineBreak / Whitespace / Nothing) { return { prerequisites:prerequisites, costs:convertNothing(costs, []), actions } }

Prerequisites = "Activate" preqs:Prerequisite+ { return preqs }

Prerequisite = Whitespace preq:(PhasePreq / ActionPreq) { return preq }

PhasePreq = timing:PhaseTiming Whitespace owner:Owner Whitespace phase:Phase { return { event: {event_object:phase, timing:timing, object_type:""}, owner:owner  } }

ActionPreq = timing:ActionTiming Whitespace actor:Owner Whitespace event_type:EventType A_Word object_type:ObjectType { return { event:{timing:timing, event_object:event_type, object_type:object_type}, owner:actor } }

ActionTiming = timing:("after"/"before") { return timing }

Costs = "," Whitespace cost:Cost+ {return cost }

Cost = owner:Owner Whitespace cost_type:CostType Whitespace amount:Amount Whitespace cost_unit:ObjectType { return {cost_type:cost_type, cost_unit:cost_unit, amount:amount, owner:owner} }

CostType = type:(Pay/Discard/Sacrifice)

Actions = (Whitespace "then" / "," ) Whitespace actions:(ChainedAction/Action)+ { return multiplyActions(actions) }

ChainedAction = start_action:Action chain_items:ChainAction+ { return concatArrays([start_action],chain_items)}

Action = head:Action_Head { return head }

ChainAction = "and" item:ChainItem { return item } 

ChainItem = Whitespace action:(MoveAction / SelectAction) { return action }

Action_Head = action:(ActorMandatory/ImplicitActor) (Whitespace / Nothing) { return { actor:action.actor, mandatory:action.mandatory, action_type:action.action.action_type, recurrence:action.action.recurrence, location_from:action.action.location_from, location_to:action.action.location_to} }
ActorMandatory = actor:Owner Whitespace mandatory:Mandatory Whitespace action:(MoveAction/SelectAction) { return { actor:actor, mandatory:mandatory, action:action} }
ImplicitActor = action:(MoveAction/SelectAction) { return { actor:"self", mandatory:false, action:action } }

MoveAction = Move Whitespace location_from:(HardMoveSelectionFrom / VariableMoveSelectionFrom) Whitespace location_to:(HardMoveSelectionTo / VariableMoveSelectionTo) { return { action_type:"move", recurrence:location_from.amount, location_from:location_from, location_to:location_to } }
HardMoveSelectionFrom = position:(Position) Whitespace amount:(Amount/AmountWord) Whitespace object_type:ObjectType Whitespace location_from:LocationFrom { return { amount:amount, owner:location_from.owner, location:location_from.location, object_type:object_type, position: position } }
HardMoveSelectionTo = location_to:LocationTo { return { owner:location_to.owner, location:location_to.location, object_type:location_to.location, position:0 } }
VariableMoveSelectionFrom = amount:VariableAmount { return {amount:amount, position:""} }
VariableMoveSelectionTo = "in" Whitespace owner:Owner Whitespace location:Location { return {owner:owner, location:location, position:""} }

SelectAction = Select Whitespace amount:(AmountWord/Amount) Whitespace object_type:ObjectType (Whitespace/Nothing) super_type:(ObjectType/Nothing) (Whitespace / Nothing) ("on"/"in") Whitespace owner:Owner Whitespace location:Location Whitespace { return { action_type:"select", recurrence:amount, super_type:super_type, location_from:{owner:owner,location:location, object_type: object_type}, location_to:"" } }

Mandatory = mandatory:("may" / "can" / "must" / Nothing) {return mandatory == "" || mandatory == "must" ? true : false }

Position = position:(Top / Bottom) { return position }

VariableAmount = amount:(VariableSingle / VariableMulti) { return amount }
VariableSingle = "it" { return 1 }
VariableMulti = "them" { return "X" }

Top = "top" { return 0 }

Bottom = "bottom" { return 999 }

ActionType = type:(Move / Select) { return type }

EventType = type:(Draw / Summon / Discard / Select / Attack / Destroy)

Move = (Draw / Summon / Discard) { return "move" }

Draw = ("drawn" / "draw") { return "draw" }

Summon = ("summoned" / "summon") { return "summon" }

Discard = ("discarded" / "discard") { return "discard" }

Select = ("selected" / "select" / "choose") { return "select" }

Attack = ("attacked" / "attack" ) { return "attack" }

Destroy = ("destroyed" / "destroy") { return "destroy" }

Pay = ("paid" / "pay" ) { return "pay" }

Sacrifice = ("sacrificed" / "sacrificed") { return "sacrifice"}

Amount = amount1:[1-9]amount2:[0-9]* { return parseInt(amount1+concatStrings(amount2)) }

AmountWord = "a" { return 1 }

ObjectType = type:(TypeCard / "player" / TypeSummonCircle / "monster" / "spell" / TypeLP ) { return type }

TypeCard = ("cards" / "card") { return "card" }

TypeLP = ("life points"/ "Life Points" / "life point"  / "life points") { return "life_point" } 

TypeSummonCircle = "summon circle" { return "summon_circle" }

LocationFrom = ("in"/"from") Whitespace owner:Owner Whitespace location:Location { return { owner:owner, location:location } }

LocationTo = "to" Whitespace owner:Owner Whitespace location:Location { return { owner:owner, location:location } }

Location = location:("deck" / "hand" / LocationTypeSummonZone / "discard_pile") { return location }

LocationTypeSummonZone = ("summon zone" / "side of the field" / "summon circles" / "summon circle") {return "summon_zone"}

Phase = phase:( StandByPhase / DrawPhase / MainPhase /  EndPhase ) { return phase }

StandByPhase = "stand by phase" { return "standByPhase" }

DrawPhase = "draw phase" { return "drawPhase" }

MainPhase = "main phase" { return "mainPhase" }

EndPhase = "end phase" { return "endPhase" }

PhaseTiming = inout:(In / Out) { return inout == 0 ? "enter" : "exit" }

In = "in" {return 0}

Out = "after" {return 1}

Owner = owner:(Opponent / Self) { return owner }

Self = ("yours" / "your" / "you") { return "self" }

Opponent = ("opponents" / "opponent" / "your opponents" / "your opponent" )  { return "opponent" }

A_Word = Whitespace "a" Whitespace { return 1 }

Whitespace = [ ]+ { return ""}

LineBreak = [\r\n]+

Nothing = ""