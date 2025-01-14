import Iris.BI.Notation
import Iris.Proofmode.Environments
import Iris.Proofmode.Expr

import Lean.PrettyPrinter.Delaborator

namespace Iris.Proofmode
open Iris.BI
open Lean Lean.Expr Lean.Meta Lean.PrettyPrinter.Delaborator Lean.PrettyPrinter.Delaborator.SubExpr

/- This file generates the state display for the Iris Proof Mode. It is implemented as a
delaborator for the function `envs_entails`. An application of this function contains a separation
logic context as an object of `Envs` and a separation logic goal. The resulting display contains
the two separation logic contexts (intuitionistic and spatial), as well as the separation
logic goal. -/

declare_syntax_cat envsDisplay
declare_syntax_cat envsDisplayLine

syntax envsDisplayLine ppDedent(ppLine envsDisplayLine)* ppDedent(ppLine term) : envsDisplay
syntax "Iris Proof Mode" : envsDisplayLine
syntax "─"+ : envsDisplayLine
syntax "─"+ " □" : envsDisplayLine
syntax "─"+ " ∗" : envsDisplayLine
syntax (ident)? " : " term : envsDisplayLine

abbrev delab := Lean.PrettyPrinter.delab

@[delab app.Iris.Proofmode.envs_entails]
def delabEnvsEntails : Delab := do
  let expr ← instantiateMVars <| ← getExpr

  -- extract environment
  let some (Γₚ, Γₛ, P) ← extractEnvsEntails? expr
    | failure

  let some Γₚ ← extractHypotheses? Γₚ
    | failure
  let some Γₛ ← extractHypotheses? Γₛ
    | failure

  -- delaborate
  let Γₚ ← delabHypotheses Γₚ
  let Γₛ ← delabHypotheses Γₛ

  let P ← unpackIprop (← delab P)

  -- build syntax
  let display ← `(envsDisplay|
    Iris Proof Mode
    ─────────────────────────────────────
    $Γₚ:envsDisplayLine*
    ───────────────────────────────────── □
    $Γₛ:envsDisplayLine*
    ───────────────────────────────────── ∗
    $P:term)
  
  -- return term
  return TSyntax.mk display
where
  extractHypotheses? (Γ : Expr) : MetaM <| Option <| Array <| Option Name × Expr := do
    let hs? := (← EnvExpr.toEnv? Γ).map (·.toList)
    let hs? ←
      hs?.mapM fun hs =>
      hs.mapM fun h => do
        let name := h.getMDataName?
        let h ← withReducible <| reduce h
        return (name, h)
    return hs?.map (·.toArray)

  delabHypotheses (Γ : Array <| Option Name × Expr) : DelabM <| Array <| TSyntax `envsDisplayLine :=
    Γ.mapM fun (name?, h) => do
      let h ← unpackIprop (← delab h)
      if let some name := name? then
        let name := mkIdent name
        `(envsDisplayLine| $name:ident : $h)
      else
        `(envsDisplayLine| : $h)

end Iris.Proofmode
