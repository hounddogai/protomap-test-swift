import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession plan calculation.
    protocol AccessionPlanStep {
        func describe() -> String
        func adjust(_ item: AccessionPlan, value: Double) -> Double
    }

    final class TieredAccessionPlanAdjuster: AccessionPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapAccessionPlanAdjuster: AccessionPlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAccessionPlanAdjuster: AccessionPlanStep {
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

        func adjust(_ item: AccessionPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAccessionPlanAdjuster: AccessionPlanStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAccessionPlanAdjuster: AccessionPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the accession plan steps in order and keeps a trace of each.
    final class AccessionPlanEngine {
        var steps: [any AccessionPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AccessionPlan) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AccessionPlanStep = steps[index]
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

        func evaluateAll(_ items: [AccessionPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAccessionPlanEngine(_ flags: Kit.Flags.Registry) -> AccessionPlanEngine {
        return AccessionPlanEngine(
            steps: [
                TieredAccessionPlanAdjuster(bounds: [1056.0, 2847.0], rates: [1.14, 1.08]),
                CapAccessionPlanAdjuster(cap: 22233.0),
                FlaggedAccessionPlanAdjuster(flags: flags, flag: "accession-plan-global", percent: -7.6),
                PercentAccessionPlanAdjuster(percent: 9.3),
                RoundingAccessionPlanAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 79557.0
        )
    }
}
