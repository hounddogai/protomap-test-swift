import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set checkpoint calculation.
    protocol OrderSetCheckpointModifier {
        func describe() -> String
        func adjust(_ item: OrderSetCheckpoint, value: Double) -> Double
    }

    final class PercentOrderSetCheckpointAdjuster: OrderSetCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredOrderSetCheckpointAdjuster: OrderSetCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OrderSetCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumOrderSetCheckpointAdjuster: OrderSetCheckpointModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OrderSetCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class OrderSetCheckpointDosageMgOffsetAdjuster: OrderSetCheckpointModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: OrderSetCheckpoint, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class RoundingOrderSetCheckpointAdjuster: OrderSetCheckpointModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocaleOrderSetCheckpointAdjuster: OrderSetCheckpointModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: OrderSetCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the order set checkpoint steps in order and keeps a trace of each.
    final class OrderSetCheckpointEngine {
        var steps: [any OrderSetCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OrderSetCheckpoint) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [OrderSetCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOrderSetCheckpointEngine() -> OrderSetCheckpointEngine {
        return OrderSetCheckpointEngine(
            steps: [
                PercentOrderSetCheckpointAdjuster(percent: -16.0),
                TieredOrderSetCheckpointAdjuster(bounds: [1650.0, 7933.0], rates: [0.88, 0.92]),
                MinimumOrderSetCheckpointAdjuster(minimum: 24.9),
                OrderSetCheckpointDosageMgOffsetAdjuster(weight: 1.21),
                RoundingOrderSetCheckpointAdjuster(step: 0.5),
                LocaleOrderSetCheckpointAdjuster(factors: ["east": 1.18]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 66376.0
        )
    }
}
