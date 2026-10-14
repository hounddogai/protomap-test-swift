import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the global worklist plan calculation.
    protocol GlobalWorklistPlanStep {
        func describe() -> String
        func adjust(_ item: GlobalWorklistPlan, value: Double) -> Double
    }

    final class RoundingGlobalWorklistPlanAdjuster: GlobalWorklistPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalWorklistPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumGlobalWorklistPlanAdjuster: GlobalWorklistPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalWorklistPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedGlobalWorklistPlanAdjuster: GlobalWorklistPlanStep {
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

        func adjust(_ item: GlobalWorklistPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelGlobalWorklistPlanAdjuster: GlobalWorklistPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: GlobalWorklistPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredGlobalWorklistPlanAdjuster: GlobalWorklistPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalWorklistPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global worklist plan steps in order and keeps a trace of each.
    final class GlobalWorklistPlanEngine {
        var steps: [any GlobalWorklistPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalWorklistPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalWorklistPlan) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalWorklistPlanStep = steps[index]
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

        func evaluateAll(_ items: [GlobalWorklistPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalWorklistPlanEngine(_ flags: Kit.Flags.Registry) -> GlobalWorklistPlanEngine {
        return GlobalWorklistPlanEngine(
            steps: [
                RoundingGlobalWorklistPlanAdjuster(step: 0.5),
                MinimumGlobalWorklistPlanAdjuster(minimum: 16.8),
                FlaggedGlobalWorklistPlanAdjuster(flags: flags, flag: "global-worklist-plan-lenient", percent: 6.9),
                LabelGlobalWorklistPlanAdjuster(factors: ["retail": 1.34, "north": 1.26, "south": 1.25]),
                TieredGlobalWorklistPlanAdjuster(bounds: [1749.0, 7599.0], rates: [0.98, 0.94]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 48437.1
        )
    }
}
