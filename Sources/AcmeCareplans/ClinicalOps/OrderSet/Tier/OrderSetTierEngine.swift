import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set tier calculation.
    protocol OrderSetTierModifier {
        func describe() -> String
        func adjust(_ item: OrderSetTier, value: Double) -> Double
    }

    final class MinimumOrderSetTierAdjuster: OrderSetTierModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OrderSetTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentOrderSetTierAdjuster: OrderSetTierModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingOrderSetTierAdjuster: OrderSetTierModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelOrderSetTierAdjuster: OrderSetTierModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: OrderSetTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedOrderSetTierAdjuster: OrderSetTierModifier {
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

        func adjust(_ item: OrderSetTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the order set tier steps in order and keeps a trace of each.
    final class OrderSetTierEngine {
        var steps: [any OrderSetTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: OrderSetTier) -> Double {
            var current = item.weightedVolume()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [OrderSetTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultOrderSetTierEngine(_ flags: Kit.Flags.Registry) -> OrderSetTierEngine {
        return OrderSetTierEngine(
            steps: [
                MinimumOrderSetTierAdjuster(minimum: 0.8),
                PercentOrderSetTierAdjuster(percent: 3.6),
                RoundingOrderSetTierAdjuster(step: 0.5),
                LabelOrderSetTierAdjuster(factors: ["west": 1.31, "central": 0.95]),
                FlaggedOrderSetTierAdjuster(flags: flags, flag: "order-set-tier-pending", percent: -1.5),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 71903.1
        )
    }
}
