import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization baseline calculation.
    protocol AuthorizationBaselineFactor {
        func describe() -> String
        func adjust(_ item: AuthorizationBaseline, value: Double) -> Double
    }

    final class CapAuthorizationBaselineAdjuster: AuthorizationBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelAuthorizationBaselineAdjuster: AuthorizationBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AuthorizationBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAuthorizationBaselineAdjuster: AuthorizationBaselineFactor {
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

        func adjust(_ item: AuthorizationBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAuthorizationBaselineAdjuster: AuthorizationBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AuthorizationBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AuthorizationBaselineUpdatedAtOffsetAdjuster: AuthorizationBaselineFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: AuthorizationBaseline, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    /// Runs the authorization baseline steps in order and keeps a trace of each.
    final class AuthorizationBaselineEngine {
        var steps: [any AuthorizationBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AuthorizationBaseline) -> Double {
            var current = item.measuredValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [AuthorizationBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAuthorizationBaselineEngine(_ flags: Kit.Flags.Registry) -> AuthorizationBaselineEngine {
        return AuthorizationBaselineEngine(
            steps: [
                CapAuthorizationBaselineAdjuster(cap: 47015.0),
                LabelAuthorizationBaselineAdjuster(factors: ["online": 1.19, "west": 0.73, "east": 0.83]),
                FlaggedAuthorizationBaselineAdjuster(
                    flags: flags,
                    flag: "authorization-baseline-default",
                    percent: -4.4
                ),
                MinimumAuthorizationBaselineAdjuster(minimum: 12.4),
                AuthorizationBaselineUpdatedAtOffsetAdjuster(weight: 0.67),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 30445.3
        )
    }
}
