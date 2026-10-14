import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study quota calculation.
    protocol StudyQuotaFactor {
        func describe() -> String
        func adjust(_ item: StudyQuota, value: Double) -> Double
    }

    final class StudyQuotaAttemptsOffsetAdjuster: StudyQuotaFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: StudyQuota, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class NameStudyQuotaAdjuster: StudyQuotaFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StudyQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStudyQuotaAdjuster: StudyQuotaFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingStudyQuotaAdjuster: StudyQuotaFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudyQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the study quota steps in order and keeps a trace of each.
    final class StudyQuotaEngine {
        var steps: [any StudyQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StudyQuota) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyQuotaFactor = steps[index]
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

        func evaluateAll(_ items: [StudyQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStudyQuotaEngine() -> StudyQuotaEngine {
        return StudyQuotaEngine(
            steps: [
                StudyQuotaAttemptsOffsetAdjuster(weight: 1.63),
                NameStudyQuotaAdjuster(factors: ["retail": 0.92]),
                CapStudyQuotaAdjuster(cap: 10279.0),
                RoundingStudyQuotaAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 83197.8
        )
    }
}
