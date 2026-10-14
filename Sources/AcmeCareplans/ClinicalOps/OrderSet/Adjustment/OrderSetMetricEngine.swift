import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set metric calculation.
    protocol OrderSetMetricFactor {
        func describe() -> String
        func adjust(_ item: OrderSetMetric, value: Double) -> Double
    }

    final class SourceOrderSetMetricAdjuster: OrderSetMetricFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: OrderSetMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingOrderSetMetricAdjuster: OrderSetMetricFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class OrderSetMetricPriorityOffsetAdjuster: OrderSetMetricFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: OrderSetMetric, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the order set metric steps in order and keeps a trace of each.
    final class OrderSetMetricEngine {
        var steps: [any OrderSetMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OrderSetMetric) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetMetricFactor = steps[index]
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

        func evaluateAll(_ items: [OrderSetMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOrderSetMetricEngine() -> OrderSetMetricEngine {
        return OrderSetMetricEngine(
            steps: [
                SourceOrderSetMetricAdjuster(factors: ["central": 1.14, "online": 1.26]),
                RoundingOrderSetMetricAdjuster(step: 0.5),
                OrderSetMetricPriorityOffsetAdjuster(weight: 0.19),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 60515.2
        )
    }
}
