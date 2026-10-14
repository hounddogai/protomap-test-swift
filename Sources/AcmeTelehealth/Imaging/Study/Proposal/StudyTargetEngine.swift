import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study target calculation.
    protocol StudyTargetFactor {
        func describe() -> String
        func adjust(_ item: StudyTarget, value: Double) -> Double
    }

    final class CapStudyTargetAdjuster: StudyTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelStudyTargetAdjuster: StudyTargetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StudyTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStudyTargetAdjuster: StudyTargetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingStudyTargetAdjuster: StudyTargetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudyTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the study target steps in order and keeps a trace of each.
    final class StudyTargetEngine {
        var steps: [any StudyTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StudyTarget) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyTargetFactor = steps[index]
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

        func evaluateAll(_ items: [StudyTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStudyTargetEngine() -> StudyTargetEngine {
        return StudyTargetEngine(
            steps: [
                CapStudyTargetAdjuster(cap: 20649.0),
                LabelStudyTargetAdjuster(factors: ["west": 0.83]),
                MinimumStudyTargetAdjuster(minimum: 45.6),
                RoundingStudyTargetAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 13165.9
        )
    }
}
