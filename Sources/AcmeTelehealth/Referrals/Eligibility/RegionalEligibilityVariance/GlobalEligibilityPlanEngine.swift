import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global eligibility plan calculation.
    protocol GlobalEligibilityPlanStep {
        func describe() -> String
        func adjust(_ item: GlobalEligibilityPlan, value: Double) -> Double
    }

    final class TieredGlobalEligibilityPlanAdjuster: GlobalEligibilityPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalEligibilityPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class GlobalEligibilityPlanCeilingOffsetAdjuster: GlobalEligibilityPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: GlobalEligibilityPlan, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class FlaggedGlobalEligibilityPlanAdjuster: GlobalEligibilityPlanStep {
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

        func adjust(_ item: GlobalEligibilityPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalEligibilityPlanAdjuster: GlobalEligibilityPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalEligibilityPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapGlobalEligibilityPlanAdjuster: GlobalEligibilityPlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalEligibilityPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global eligibility plan steps in order and keeps a trace of each.
    final class GlobalEligibilityPlanEngine {
        var steps: [any GlobalEligibilityPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalEligibilityPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalEligibilityPlan) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalEligibilityPlanStep = steps[index]
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

        func evaluateAll(_ items: [GlobalEligibilityPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalEligibilityPlanEngine(_ flags: Kit.Flags.Registry) -> GlobalEligibilityPlanEngine {
        return GlobalEligibilityPlanEngine(
            steps: [
                TieredGlobalEligibilityPlanAdjuster(bounds: [130.0, 5056.0, 8656.0], rates: [0.93, 1.1, 1.07]),
                GlobalEligibilityPlanCeilingOffsetAdjuster(weight: 1.95),
                FlaggedGlobalEligibilityPlanAdjuster(
                    flags: flags,
                    flag: "global-eligibility-plan-seasonal",
                    percent: -3.7
                ),
                MinimumGlobalEligibilityPlanAdjuster(minimum: 31.0),
                CapGlobalEligibilityPlanAdjuster(cap: 1085.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 53214.5
        )
    }
}
