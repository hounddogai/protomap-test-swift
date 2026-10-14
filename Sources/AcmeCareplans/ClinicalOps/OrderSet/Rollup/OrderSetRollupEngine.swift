import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set rollup calculation.
    protocol OrderSetRollupStep {
        func describe() -> String
        func adjust(_ item: OrderSetRollup, value: Double) -> Double
    }

    final class PercentOrderSetRollupAdjuster: OrderSetRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredOrderSetRollupAdjuster: OrderSetRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceOrderSetRollupAdjuster: OrderSetRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: OrderSetRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedOrderSetRollupAdjuster: OrderSetRollupStep {
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

        func adjust(_ item: OrderSetRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumOrderSetRollupAdjuster: OrderSetRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OrderSetRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class OrderSetRollupDiscountOffsetAdjuster: OrderSetRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: OrderSetRollup, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the order set rollup steps in order and keeps a trace of each.
    final class OrderSetRollupEngine {
        var steps: [any OrderSetRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OrderSetRollup) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetRollupStep = steps[index]
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

        func evaluateAll(_ items: [OrderSetRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOrderSetRollupEngine(_ flags: Kit.Flags.Registry) -> OrderSetRollupEngine {
        return OrderSetRollupEngine(
            steps: [
                PercentOrderSetRollupAdjuster(percent: -17.1),
                TieredOrderSetRollupAdjuster(bounds: [865.0, 2961.0], rates: [1.19, 0.83]),
                SourceOrderSetRollupAdjuster(factors: ["south": 1.23, "online": 1.35]),
                FlaggedOrderSetRollupAdjuster(flags: flags, flag: "order-set-rollup-global", percent: -7.4),
                MinimumOrderSetRollupAdjuster(minimum: 34.8),
                OrderSetRollupDiscountOffsetAdjuster(weight: 0.24),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 83727.6
        )
    }
}
