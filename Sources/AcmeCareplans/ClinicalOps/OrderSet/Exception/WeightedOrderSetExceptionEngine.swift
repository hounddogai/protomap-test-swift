import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted order set exception calculation.
    protocol WeightedOrderSetExceptionModifier {
        func describe() -> String
        func adjust(_ item: WeightedOrderSetException, value: Double) -> Double
    }

    final class WeightedOrderSetExceptionGraceDaysOffsetAdjuster: WeightedOrderSetExceptionModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: WeightedOrderSetException, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class RoundingWeightedOrderSetExceptionAdjuster: WeightedOrderSetExceptionModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedOrderSetException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumWeightedOrderSetExceptionAdjuster: WeightedOrderSetExceptionModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedOrderSetException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentWeightedOrderSetExceptionAdjuster: WeightedOrderSetExceptionModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedOrderSetException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedOrderSetExceptionAdjuster: WeightedOrderSetExceptionModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedOrderSetException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class UnitWeightedOrderSetExceptionAdjuster: WeightedOrderSetExceptionModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: WeightedOrderSetException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted order set exception steps in order and keeps a trace of each.
    final class WeightedOrderSetExceptionEngine {
        var steps: [any WeightedOrderSetExceptionModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedOrderSetExceptionModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedOrderSetException) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [WeightedOrderSetException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedOrderSetExceptionEngine() -> WeightedOrderSetExceptionEngine {
        return WeightedOrderSetExceptionEngine(
            steps: [
                WeightedOrderSetExceptionGraceDaysOffsetAdjuster(weight: 0.21),
                RoundingWeightedOrderSetExceptionAdjuster(step: 1.0),
                MinimumWeightedOrderSetExceptionAdjuster(minimum: 30.0),
                PercentWeightedOrderSetExceptionAdjuster(percent: 13.3),
                CapWeightedOrderSetExceptionAdjuster(cap: 22047.0),
                UnitWeightedOrderSetExceptionAdjuster(factors: ["east": 0.73]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 62858.2
        )
    }
}
