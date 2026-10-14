import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential policy calculation.
    protocol CredentialPolicyFactor {
        func describe() -> String
        func adjust(_ item: CredentialPolicy, value: Double) -> Double
    }

    final class PercentCredentialPolicyAdjuster: CredentialPolicyFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCredentialPolicyAdjuster: CredentialPolicyFactor {
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

        func adjust(_ item: CredentialPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCredentialPolicyAdjuster: CredentialPolicyFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CredentialPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCredentialPolicyAdjuster: CredentialPolicyFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitCredentialPolicyAdjuster: CredentialPolicyFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CredentialPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the credential policy steps in order and keeps a trace of each.
    final class CredentialPolicyEngine {
        var steps: [any CredentialPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CredentialPolicy) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CredentialPolicyFactor = steps[index]
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

        func evaluateAll(_ items: [CredentialPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCredentialPolicyEngine(_ flags: Kit.Flags.Registry) -> CredentialPolicyEngine {
        return CredentialPolicyEngine(
            steps: [
                PercentCredentialPolicyAdjuster(percent: 1.0),
                FlaggedCredentialPolicyAdjuster(flags: flags, flag: "credential-policy-fallback", percent: -3.8),
                RoundingCredentialPolicyAdjuster(step: 0.25),
                TieredCredentialPolicyAdjuster(bounds: [2300.0, 5136.0], rates: [1.2, 0.93]),
                UnitCredentialPolicyAdjuster(factors: ["online": 1.17, "south": 1.3]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 87803.6
        )
    }
}
