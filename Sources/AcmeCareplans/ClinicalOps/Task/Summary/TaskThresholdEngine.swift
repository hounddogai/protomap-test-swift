import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task threshold calculation.
    protocol TaskThresholdModifier {
        func describe() -> String
        func adjust(_ item: TaskThreshold, value: Double) -> Double
    }

    final class TieredTaskThresholdAdjuster: TaskThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumTaskThresholdAdjuster: TaskThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TaskThresholdCopayOffsetAdjuster: TaskThresholdModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: TaskThreshold, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class RoundingTaskThresholdAdjuster: TaskThresholdModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TaskThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentTaskThresholdAdjuster: TaskThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TaskThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceTaskThresholdAdjuster: TaskThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: TaskThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the task threshold steps in order and keeps a trace of each.
    final class TaskThresholdEngine {
        var steps: [any TaskThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TaskThreshold) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskThresholdModifier = steps[index]
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

        func evaluateAll(_ items: [TaskThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTaskThresholdEngine() -> TaskThresholdEngine {
        return TaskThresholdEngine(
            steps: [
                TieredTaskThresholdAdjuster(bounds: [1176.0, 2467.0, 3937.0, 5065.0], rates: [0.95, 0.84, 0.89, 0.98]),
                MinimumTaskThresholdAdjuster(minimum: 38.8),
                TaskThresholdCopayOffsetAdjuster(weight: 1.54),
                RoundingTaskThresholdAdjuster(step: 1.0),
                PercentTaskThresholdAdjuster(percent: 20.0),
                SourceTaskThresholdAdjuster(factors: ["retail": 1.26, "online": 0.78, "south": 1.39]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 67596.9
        )
    }
}
