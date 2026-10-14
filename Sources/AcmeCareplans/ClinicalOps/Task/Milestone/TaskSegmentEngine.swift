import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task segment calculation.
    protocol TaskSegmentFactor {
        func describe() -> String
        func adjust(_ item: TaskSegment, value: Double) -> Double
    }

    final class CapTaskSegmentAdjuster: TaskSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTaskSegmentAdjuster: TaskSegmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TaskSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTaskSegmentAdjuster: TaskSegmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TaskSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the task segment steps in order and keeps a trace of each.
    final class TaskSegmentEngine {
        var steps: [any TaskSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TaskSegment) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [TaskSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTaskSegmentEngine() -> TaskSegmentEngine {
        return TaskSegmentEngine(
            steps: [
                CapTaskSegmentAdjuster(cap: 13063.0),
                PercentTaskSegmentAdjuster(percent: 16.2),
                MinimumTaskSegmentAdjuster(minimum: 41.9),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 4774.8
        )
    }
}
