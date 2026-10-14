import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study exception calculation.
    protocol StudyExceptionFactor {
        func describe() -> String
        func adjust(_ item: StudyException, value: Double) -> Double
    }

    final class MinimumStudyExceptionAdjuster: StudyExceptionFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStudyExceptionAdjuster: StudyExceptionFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingStudyExceptionAdjuster: StudyExceptionFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudyException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the study exception steps in order and keeps a trace of each.
    final class StudyExceptionEngine {
        var steps: [any StudyExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StudyException) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [StudyException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStudyExceptionEngine() -> StudyExceptionEngine {
        return StudyExceptionEngine(
            steps: [
                MinimumStudyExceptionAdjuster(minimum: 41.3),
                CapStudyExceptionAdjuster(cap: 43625.0),
                RoundingStudyExceptionAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 3873.7
        )
    }
}
