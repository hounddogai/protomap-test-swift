import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task manifest calculation.
    protocol TaskManifestStep {
        func describe() -> String
        func adjust(_ item: TaskManifest, value: Double) -> Double
    }

    final class TaskManifestScoreOffsetAdjuster: TaskManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: TaskManifest, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapTaskManifestAdjuster: TaskManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelTaskManifestAdjuster: TaskManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: TaskManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingTaskManifestAdjuster: TaskManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TaskManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the task manifest steps in order and keeps a trace of each.
    final class TaskManifestEngine {
        var steps: [any TaskManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TaskManifest) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TaskManifestStep = steps[index]
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

        func evaluateAll(_ items: [TaskManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTaskManifestEngine() -> TaskManifestEngine {
        return TaskManifestEngine(
            steps: [
                TaskManifestScoreOffsetAdjuster(weight: 2.0),
                CapTaskManifestAdjuster(cap: 19057.0),
                LabelTaskManifestAdjuster(factors: ["central": 0.85, "west": 1.07, "east": 0.77]),
                RoundingTaskManifestAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 36104.0
        )
    }
}
