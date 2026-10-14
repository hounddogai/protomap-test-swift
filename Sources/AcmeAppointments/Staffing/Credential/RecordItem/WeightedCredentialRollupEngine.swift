import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the weighted credential rollup calculation.
    protocol WeightedCredentialRollupModifier {
        func describe() -> String
        func adjust(_ item: WeightedCredentialRollup, value: Double) -> Double
    }

    final class ChannelWeightedCredentialRollupAdjuster: WeightedCredentialRollupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: WeightedCredentialRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedWeightedCredentialRollupAdjuster: WeightedCredentialRollupModifier {
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

        func adjust(_ item: WeightedCredentialRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWeightedCredentialRollupAdjuster: WeightedCredentialRollupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedCredentialRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapWeightedCredentialRollupAdjuster: WeightedCredentialRollupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedCredentialRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumWeightedCredentialRollupAdjuster: WeightedCredentialRollupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedCredentialRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the weighted credential rollup steps in order and keeps a trace of each.
    final class WeightedCredentialRollupEngine {
        var steps: [any WeightedCredentialRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedCredentialRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedCredentialRollup) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedCredentialRollupModifier = steps[index]
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

        func evaluateAll(_ items: [WeightedCredentialRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedCredentialRollupEngine(_ flags: Kit.Flags.Registry) -> WeightedCredentialRollupEngine {
        return WeightedCredentialRollupEngine(
            steps: [
                ChannelWeightedCredentialRollupAdjuster(factors: ["north": 1.14, "central": 1.22, "west": 0.74]),
                FlaggedWeightedCredentialRollupAdjuster(
                    flags: flags,
                    flag: "weighted-credential-rollup-adaptive",
                    percent: 1.0
                ),
                TieredWeightedCredentialRollupAdjuster(
                    bounds: [4251.0, 4448.0, 5799.0, 8181.0],
                    rates: [1.17, 0.97, 0.91, 1.06]
                ),
                CapWeightedCredentialRollupAdjuster(cap: 40641.0),
                MinimumWeightedCredentialRollupAdjuster(minimum: 14.0),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 85317.9
        )
    }
}
