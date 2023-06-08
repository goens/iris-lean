import Lean.Elab.Tactic
import Lean.Meta.Tactic.Util

namespace Iris.Std
open Lean Lean.Elab.Tactic Lean.Meta

/-- Apply the theorem with the name `name` to the goal `goal`. The flag `recover` is set to `false`
and the transparency mode is set to `reducible`. Only non-dependent arguments of the applied
theorem are turned into goals. -/
def apply' (goal : MVarId) (name : Name) : TacticM <| Option <| List MVarId := do
  let some ci := (← getEnv).find? name
    | return none
  let some value := ci.value?
    | return none

  -- Set synthAssignedInstances to true, approx false. Seemed like right defaults, but just a guess.
  let goals ← withoutRecover <| withReducible <| goal.apply value ⟨.nonDependentOnly, true, false⟩
  setGoals <| goals ++ (← getUnsolvedGoals)
  return goals

/-- Find the goal with the tag `tag`. -/
def findGoalFromTag? (tag : Name) : TacticM <| Option MVarId := do
  (← getUnsolvedGoals).findM? fun goal => do return (← goal.getTag) == tag

/-- Execute the function `f` with the single goal `goal` and restore all current goals after
the execution. -/
def withFocus (goal : MVarId) (f : TacticM α) : TacticM α := do
  let goals ← getUnsolvedGoals
  setGoals [goal]
  let result ← f
  setGoals <| goals ++ (← getUnsolvedGoals)
  return result

end Iris.Std
