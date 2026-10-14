import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment batch calculation.
    protocol AssessmentBatchFactor {
        func describe() -> String
        func adjust(_ item: AssessmentBatch, value: Double) -> Double
    }

    final class CapAssessmentBatchAdjuster: AssessmentBatchFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AssessmentBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAssessmentBatchAdjuster: AssessmentBatchFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: AssessmentBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AssessmentBatchScoreOffsetAdjuster: AssessmentBatchFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: AssessmentBatch, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    /// Runs the assessment batch steps in order and keeps a trace of each.
    final class AssessmentBatchEngine {
        var steps: [any AssessmentBatchFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentBatchFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentBatch) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentBatchFactor = steps[index]
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

        func evaluateAll(_ items: [AssessmentBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentBatchEngine(_ flags: Kit.Flags.Registry) -> AssessmentBatchEngine {
        return AssessmentBatchEngine(
            steps: [
                CapAssessmentBatchAdjuster(cap: 3292.0),
                FlaggedAssessmentBatchAdjuster(flags: flags, flag: "assessment-batch-seasonal", percent: 4.7),
                AssessmentBatchScoreOffsetAdjuster(weight: 1.72),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 51554.5
        )
    }
}
