import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential plan calculation.
    protocol CredentialPlanAdjuster {
        func describe() -> String
        func adjust(_ item: CredentialPlan, value: Double) -> Double
    }

    final class LabelCredentialPlanAdjuster: CredentialPlanAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CredentialPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCredentialPlanAdjuster: CredentialPlanAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CredentialPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCredentialPlanAdjuster: CredentialPlanAdjuster {
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

        func adjust(_ item: CredentialPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentCredentialPlanAdjuster: CredentialPlanAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCredentialPlanAdjuster: CredentialPlanAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the credential plan steps in order and keeps a trace of each.
    final class CredentialPlanEngine {
        var steps: [any CredentialPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CredentialPlan) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CredentialPlanAdjuster = steps[index]
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

        func evaluateAll(_ items: [CredentialPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCredentialPlanEngine(_ flags: Kit.Flags.Registry) -> CredentialPlanEngine {
        return CredentialPlanEngine(
            steps: [
                LabelCredentialPlanAdjuster(factors: ["east": 1.38, "south": 1.04]),
                RoundingCredentialPlanAdjuster(step: 0.5),
                FlaggedCredentialPlanAdjuster(flags: flags, flag: "credential-plan-global", percent: 8.5),
                PercentCredentialPlanAdjuster(percent: 21.4),
                TieredCredentialPlanAdjuster(bounds: [5868.0, 8846.0], rates: [1.08, 0.95]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 9352.3
        )
    }
}
