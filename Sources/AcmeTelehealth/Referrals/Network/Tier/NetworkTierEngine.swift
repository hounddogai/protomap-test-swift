import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network tier calculation.
    protocol NetworkTierStep {
        func describe() -> String
        func adjust(_ item: NetworkTier, value: Double) -> Double
    }

    final class FlaggedNetworkTierAdjuster: NetworkTierStep {
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

        func adjust(_ item: NetworkTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentNetworkTierAdjuster: NetworkTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingNetworkTierAdjuster: NetworkTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: NetworkTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredNetworkTierAdjuster: NetworkTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleNetworkTierAdjuster: NetworkTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: NetworkTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the network tier steps in order and keeps a trace of each.
    final class NetworkTierEngine {
        var steps: [any NetworkTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: NetworkTier) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any NetworkTierStep = steps[index]
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

        func evaluateAll(_ items: [NetworkTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultNetworkTierEngine(_ flags: Kit.Flags.Registry) -> NetworkTierEngine {
        return NetworkTierEngine(
            steps: [
                FlaggedNetworkTierAdjuster(flags: flags, flag: "network-tier-adaptive", percent: 2.4),
                PercentNetworkTierAdjuster(percent: 12.0),
                RoundingNetworkTierAdjuster(step: 0.25),
                TieredNetworkTierAdjuster(bounds: [521.0, 1782.0, 3240.0], rates: [1.12, 1.16, 1.12]),
                TitleNetworkTierAdjuster(factors: ["retail": 0.74]),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 51934.8
        )
    }
}
