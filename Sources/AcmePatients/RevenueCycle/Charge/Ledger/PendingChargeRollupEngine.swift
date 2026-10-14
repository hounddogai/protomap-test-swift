import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending charge rollup calculation.
    protocol PendingChargeRollupModifier {
        func describe() -> String
        func adjust(_ item: PendingChargeRollup, value: Double) -> Double
    }

    final class LabelPendingChargeRollupAdjuster: PendingChargeRollupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingChargeRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPendingChargeRollupAdjuster: PendingChargeRollupModifier {
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

        func adjust(_ item: PendingChargeRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPendingChargeRollupAdjuster: PendingChargeRollupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingChargeRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPendingChargeRollupAdjuster: PendingChargeRollupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingChargeRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPendingChargeRollupAdjuster: PendingChargeRollupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingChargeRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending charge rollup steps in order and keeps a trace of each.
    final class PendingChargeRollupEngine {
        var steps: [any PendingChargeRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingChargeRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingChargeRollup) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingChargeRollupModifier = steps[index]
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

        func evaluateAll(_ items: [PendingChargeRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingChargeRollupEngine(_ flags: Kit.Flags.Registry) -> PendingChargeRollupEngine {
        return PendingChargeRollupEngine(
            steps: [
                LabelPendingChargeRollupAdjuster(factors: ["east": 1.32, "retail": 0.92]),
                FlaggedPendingChargeRollupAdjuster(
                    flags: flags,
                    flag: "pending-charge-rollup-adaptive",
                    percent: -5.5
                ),
                MinimumPendingChargeRollupAdjuster(minimum: 22.7),
                CapPendingChargeRollupAdjuster(cap: 45674.0),
                TieredPendingChargeRollupAdjuster(bounds: [2826.0, 7873.0], rates: [0.99, 1.13]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 68609.0
        )
    }
}
