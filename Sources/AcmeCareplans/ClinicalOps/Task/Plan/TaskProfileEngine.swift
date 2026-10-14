import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task profile calculation.
    protocol TaskProfileAdjuster {
        func describe() -> String
        func adjust(_ item: TaskProfile, value: Double) -> Double
    }

    final class PercentTaskProfileAdjuster: TaskProfileAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TaskProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelTaskProfileAdjuster: TaskProfileAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: TaskProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTaskProfileAdjuster: TaskProfileAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TaskProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the task profile steps in order and keeps a trace of each.
    final class TaskProfileEngine {
        var steps: [any TaskProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TaskProfile) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskProfileAdjuster = steps[index]
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

        func evaluateAll(_ items: [TaskProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTaskProfileEngine() -> TaskProfileEngine {
        return TaskProfileEngine(
            steps: [
                PercentTaskProfileAdjuster(percent: -20.9),
                LabelTaskProfileAdjuster(factors: ["east": 0.82]),
                TieredTaskProfileAdjuster(bounds: [1818.0, 2626.0, 9186.0], rates: [0.84, 0.99, 0.9]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 12300.4
        )
    }
}
