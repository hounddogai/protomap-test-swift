import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set digest calculation.
    protocol OrderSetDigestModifier {
        func describe() -> String
        func adjust(_ item: OrderSetDigest, value: Double) -> Double
    }

    final class PercentOrderSetDigestAdjuster: OrderSetDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedOrderSetDigestAdjuster: OrderSetDigestModifier {
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

        func adjust(_ item: OrderSetDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class OrderSetDigestBatchSizeOffsetAdjuster: OrderSetDigestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: OrderSetDigest, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class MinimumOrderSetDigestAdjuster: OrderSetDigestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OrderSetDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingOrderSetDigestAdjuster: OrderSetDigestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the order set digest steps in order and keeps a trace of each.
    final class OrderSetDigestEngine {
        var steps: [any OrderSetDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OrderSetDigest) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetDigestModifier = steps[index]
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

        func evaluateAll(_ items: [OrderSetDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOrderSetDigestEngine(_ flags: Kit.Flags.Registry) -> OrderSetDigestEngine {
        return OrderSetDigestEngine(
            steps: [
                PercentOrderSetDigestAdjuster(percent: -22.4),
                FlaggedOrderSetDigestAdjuster(flags: flags, flag: "order-set-digest-rolling", percent: 5.6),
                OrderSetDigestBatchSizeOffsetAdjuster(weight: 1.09),
                MinimumOrderSetDigestAdjuster(minimum: 48.9),
                RoundingOrderSetDigestAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 72319.8
        )
    }
}
