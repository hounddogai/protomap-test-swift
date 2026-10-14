import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary plan calculation.
    protocol FormularyPlanModifier {
        func describe() -> String
        func adjust(_ item: FormularyPlan, value: Double) -> Double
    }

    final class FlaggedFormularyPlanAdjuster: FormularyPlanModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: FormularyPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFormularyPlanAdjuster: FormularyPlanModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FormularyPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFormularyPlanAdjuster: FormularyPlanModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the formulary plan steps in order and keeps a trace of each.
    final class FormularyPlanEngine {
        var steps: [any FormularyPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FormularyPlan) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyPlanModifier = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [FormularyPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFormularyPlanEngine(_ flags: Kit.Flags.Registry) -> FormularyPlanEngine {
        return FormularyPlanEngine(
            steps: [
                FlaggedFormularyPlanAdjuster(flags: flags, flag: "formulary-plan-batched", percent: 6.9),
                RoundingFormularyPlanAdjuster(step: 0.25),
                PercentFormularyPlanAdjuster(percent: -0.3),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 76521.9
        )
    }
}
