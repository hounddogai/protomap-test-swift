import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global credential tier calculation.
    protocol GlobalCredentialTierAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalCredentialTier, value: Double) -> Double
    }

    final class FlaggedGlobalCredentialTierAdjuster: GlobalCredentialTierAdjuster {
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

        func adjust(_ item: GlobalCredentialTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalCredentialTierAdjuster: GlobalCredentialTierAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalCredentialTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredGlobalCredentialTierAdjuster: GlobalCredentialTierAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalCredentialTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalCredentialTierAdjuster: GlobalCredentialTierAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalCredentialTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global credential tier steps in order and keeps a trace of each.
    final class GlobalCredentialTierEngine {
        var steps: [any GlobalCredentialTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCredentialTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalCredentialTier) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCredentialTierAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalCredentialTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalCredentialTierEngine(_ flags: Kit.Flags.Registry) -> GlobalCredentialTierEngine {
        return GlobalCredentialTierEngine(
            steps: [
                FlaggedGlobalCredentialTierAdjuster(
                    flags: flags,
                    flag: "global-credential-tier-strict",
                    percent: -0.9
                ),
                MinimumGlobalCredentialTierAdjuster(minimum: 6.2),
                TieredGlobalCredentialTierAdjuster(bounds: [4124.0, 8994.0], rates: [0.89, 1.17]),
                PercentGlobalCredentialTierAdjuster(percent: 10.4),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 59086.9
        )
    }
}
