import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set adjustment calculation.
    protocol OrderSetAdjustmentStep {
        func describe() -> String
        func adjust(_ item: OrderSetAdjustment, value: Double) -> Double
    }

    final class PercentOrderSetAdjustmentAdjuster: OrderSetAdjustmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedOrderSetAdjustmentAdjuster: OrderSetAdjustmentStep {
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

        func adjust(_ item: OrderSetAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumOrderSetAdjustmentAdjuster: OrderSetAdjustmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OrderSetAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredOrderSetAdjustmentAdjuster: OrderSetAdjustmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the order set adjustment steps in order and keeps a trace of each.
    final class OrderSetAdjustmentEngine {
        var steps: [any OrderSetAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: OrderSetAdjustment) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetAdjustmentStep = steps[index]
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

        func evaluateAll(_ items: [OrderSetAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultOrderSetAdjustmentEngine(_ flags: Kit.Flags.Registry) -> OrderSetAdjustmentEngine {
        return OrderSetAdjustmentEngine(
            steps: [
                PercentOrderSetAdjustmentAdjuster(percent: 20.2),
                FlaggedOrderSetAdjustmentAdjuster(flags: flags, flag: "order-set-adjustment-weighted", percent: 3.6),
                MinimumOrderSetAdjustmentAdjuster(minimum: 22.6),
                TieredOrderSetAdjustmentAdjuster(
                    bounds: [2521.0, 2952.0, 3555.0, 5827.0],
                    rates: [0.87, 1.18, 0.91, 0.9]
                ),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 11699.4
        )
    }
}
