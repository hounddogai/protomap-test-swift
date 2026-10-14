import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge rollup calculation.
    protocol ChargeRollupFactor {
        func describe() -> String
        func adjust(_ item: ChargeRollup, value: Double) -> Double
    }

    final class TieredChargeRollupAdjuster: ChargeRollupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameChargeRollupAdjuster: ChargeRollupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ChargeRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingChargeRollupAdjuster: ChargeRollupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedChargeRollupAdjuster: ChargeRollupFactor {
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

        func adjust(_ item: ChargeRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapChargeRollupAdjuster: ChargeRollupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChargeRollupMaximumOffsetAdjuster: ChargeRollupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: ChargeRollup, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    /// Runs the charge rollup steps in order and keeps a trace of each.
    final class ChargeRollupEngine {
        var steps: [any ChargeRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ChargeRollup) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeRollupFactor = steps[index]
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

        func evaluateAll(_ items: [ChargeRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultChargeRollupEngine(_ flags: Kit.Flags.Registry) -> ChargeRollupEngine {
        return ChargeRollupEngine(
            steps: [
                TieredChargeRollupAdjuster(bounds: [1761.0, 3276.0, 9115.0], rates: [1.0, 0.85, 1.08]),
                NameChargeRollupAdjuster(factors: ["retail": 1.16]),
                RoundingChargeRollupAdjuster(step: 1.0),
                FlaggedChargeRollupAdjuster(flags: flags, flag: "charge-rollup-adaptive", percent: 1.1),
                CapChargeRollupAdjuster(cap: 20424.0),
                ChargeRollupMaximumOffsetAdjuster(weight: 0.42),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 92561.3
        )
    }
}
