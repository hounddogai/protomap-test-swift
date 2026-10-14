import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set variance calculation.
    protocol OrderSetVarianceModifier {
        func describe() -> String
        func adjust(_ item: OrderSetVariance, value: Double) -> Double
    }

    final class MinimumOrderSetVarianceAdjuster: OrderSetVarianceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OrderSetVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentOrderSetVarianceAdjuster: OrderSetVarianceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedOrderSetVarianceAdjuster: OrderSetVarianceModifier {
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

        func adjust(_ item: OrderSetVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapOrderSetVarianceAdjuster: OrderSetVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OrderSetVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CategoryOrderSetVarianceAdjuster: OrderSetVarianceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: OrderSetVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingOrderSetVarianceAdjuster: OrderSetVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the order set variance steps in order and keeps a trace of each.
    final class OrderSetVarianceEngine {
        var steps: [any OrderSetVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OrderSetVariance) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [OrderSetVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOrderSetVarianceEngine(_ flags: Kit.Flags.Registry) -> OrderSetVarianceEngine {
        return OrderSetVarianceEngine(
            steps: [
                MinimumOrderSetVarianceAdjuster(minimum: 24.9),
                PercentOrderSetVarianceAdjuster(percent: -11.3),
                FlaggedOrderSetVarianceAdjuster(flags: flags, flag: "order-set-variance-manual", percent: -1.0),
                CapOrderSetVarianceAdjuster(cap: 39901.0),
                CategoryOrderSetVarianceAdjuster(factors: ["online": 0.92]),
                RoundingOrderSetVarianceAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 63105.4
        )
    }
}
