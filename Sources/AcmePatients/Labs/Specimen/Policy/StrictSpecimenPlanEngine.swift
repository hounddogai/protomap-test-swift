import AcmePlatform
import Foundation

extension Labs {
    /// One step of the strict specimen plan calculation.
    protocol StrictSpecimenPlanModifier {
        func describe() -> String
        func adjust(_ item: StrictSpecimenPlan, value: Double) -> Double
    }

    final class MinimumStrictSpecimenPlanAdjuster: StrictSpecimenPlanModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictSpecimenPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelStrictSpecimenPlanAdjuster: StrictSpecimenPlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StrictSpecimenPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingStrictSpecimenPlanAdjuster: StrictSpecimenPlanModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictSpecimenPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StrictSpecimenPlanCopayOffsetAdjuster: StrictSpecimenPlanModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: StrictSpecimenPlan, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class FlaggedStrictSpecimenPlanAdjuster: StrictSpecimenPlanModifier {
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

        func adjust(_ item: StrictSpecimenPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict specimen plan steps in order and keeps a trace of each.
    final class StrictSpecimenPlanEngine {
        var steps: [any StrictSpecimenPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictSpecimenPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictSpecimenPlan) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictSpecimenPlanModifier = steps[index]
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

        func evaluateAll(_ items: [StrictSpecimenPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictSpecimenPlanEngine(_ flags: Kit.Flags.Registry) -> StrictSpecimenPlanEngine {
        return StrictSpecimenPlanEngine(
            steps: [
                MinimumStrictSpecimenPlanAdjuster(minimum: 48.8),
                LabelStrictSpecimenPlanAdjuster(factors: ["east": 1.35, "central": 1.06]),
                RoundingStrictSpecimenPlanAdjuster(step: 0.05),
                StrictSpecimenPlanCopayOffsetAdjuster(weight: 0.52),
                FlaggedStrictSpecimenPlanAdjuster(flags: flags, flag: "strict-specimen-plan-seasonal", percent: -2.8),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 86842.6
        )
    }
}
