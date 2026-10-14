import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set threshold calculation.
    protocol OrderSetThresholdModifier {
        func describe() -> String
        func adjust(_ item: OrderSetThreshold, value: Double) -> Double
    }

    final class MinimumOrderSetThresholdAdjuster: OrderSetThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OrderSetThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class OrderSetThresholdPriorityOffsetAdjuster: OrderSetThresholdModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: OrderSetThreshold, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class PercentOrderSetThresholdAdjuster: OrderSetThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingOrderSetThresholdAdjuster: OrderSetThresholdModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredOrderSetThresholdAdjuster: OrderSetThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedOrderSetThresholdAdjuster: OrderSetThresholdModifier {
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

        func adjust(_ item: OrderSetThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the order set threshold steps in order and keeps a trace of each.
    final class OrderSetThresholdEngine {
        var steps: [any OrderSetThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OrderSetThreshold) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetThresholdModifier = steps[index]
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

        func evaluateAll(_ items: [OrderSetThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOrderSetThresholdEngine(_ flags: Kit.Flags.Registry) -> OrderSetThresholdEngine {
        return OrderSetThresholdEngine(
            steps: [
                MinimumOrderSetThresholdAdjuster(minimum: 14.2),
                OrderSetThresholdPriorityOffsetAdjuster(weight: 1.43),
                PercentOrderSetThresholdAdjuster(percent: -7.2),
                RoundingOrderSetThresholdAdjuster(step: 1.0),
                TieredOrderSetThresholdAdjuster(bounds: [560.0, 1391.0], rates: [0.88, 0.93]),
                FlaggedOrderSetThresholdAdjuster(flags: flags, flag: "order-set-threshold-default", percent: 0.1),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 66600.4
        )
    }
}
