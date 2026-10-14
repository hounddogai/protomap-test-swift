import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set segment calculation.
    protocol OrderSetSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: OrderSetSegment, value: Double) -> Double
    }

    final class LocaleOrderSetSegmentAdjuster: OrderSetSegmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: OrderSetSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumOrderSetSegmentAdjuster: OrderSetSegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OrderSetSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingOrderSetSegmentAdjuster: OrderSetSegmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the order set segment steps in order and keeps a trace of each.
    final class OrderSetSegmentEngine {
        var steps: [any OrderSetSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OrderSetSegment) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [OrderSetSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOrderSetSegmentEngine() -> OrderSetSegmentEngine {
        return OrderSetSegmentEngine(
            steps: [
                LocaleOrderSetSegmentAdjuster(factors: ["central": 1.17, "online": 0.75, "west": 0.88]),
                MinimumOrderSetSegmentAdjuster(minimum: 7.9),
                RoundingOrderSetSegmentAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 24093.7
        )
    }
}
