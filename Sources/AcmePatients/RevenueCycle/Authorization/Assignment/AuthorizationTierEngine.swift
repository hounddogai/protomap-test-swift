import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization tier calculation.
    protocol AuthorizationTierStep {
        func describe() -> String
        func adjust(_ item: AuthorizationTier, value: Double) -> Double
    }

    final class MinimumAuthorizationTierAdjuster: AuthorizationTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AuthorizationTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAuthorizationTierAdjuster: AuthorizationTierStep {
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

        func adjust(_ item: AuthorizationTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAuthorizationTierAdjuster: AuthorizationTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the authorization tier steps in order and keeps a trace of each.
    final class AuthorizationTierEngine {
        var steps: [any AuthorizationTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AuthorizationTier) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AuthorizationTierStep = steps[index]
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

        func evaluateAll(_ items: [AuthorizationTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAuthorizationTierEngine(_ flags: Kit.Flags.Registry) -> AuthorizationTierEngine {
        return AuthorizationTierEngine(
            steps: [
                MinimumAuthorizationTierAdjuster(minimum: 10.7),
                FlaggedAuthorizationTierAdjuster(flags: flags, flag: "authorization-tier-lenient", percent: -8.7),
                TieredAuthorizationTierAdjuster(
                    bounds: [805.0, 2962.0, 3468.0, 7020.0],
                    rates: [1.14, 0.82, 0.97, 0.88]
                ),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 35337.1
        )
    }
}
