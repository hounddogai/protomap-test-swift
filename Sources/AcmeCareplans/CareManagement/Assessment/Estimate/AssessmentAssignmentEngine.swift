import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment assignment calculation.
    protocol AssessmentAssignmentFactor {
        func describe() -> String
        func adjust(_ item: AssessmentAssignment, value: Double) -> Double
    }

    final class PercentAssessmentAssignmentAdjuster: AssessmentAssignmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AssessmentAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAssessmentAssignmentAdjuster: AssessmentAssignmentFactor {
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

        func adjust(_ item: AssessmentAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleAssessmentAssignmentAdjuster: AssessmentAssignmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AssessmentAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the assessment assignment steps in order and keeps a trace of each.
    final class AssessmentAssignmentEngine {
        var steps: [any AssessmentAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentAssignment) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentAssignmentFactor = steps[index]
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

        func evaluateAll(_ items: [AssessmentAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentAssignmentEngine(_ flags: Kit.Flags.Registry) -> AssessmentAssignmentEngine {
        return AssessmentAssignmentEngine(
            steps: [
                PercentAssessmentAssignmentAdjuster(percent: 15.8),
                FlaggedAssessmentAssignmentAdjuster(
                    flags: flags,
                    flag: "assessment-assignment-primary",
                    percent: -3.0
                ),
                TitleAssessmentAssignmentAdjuster(factors: ["east": 1.16]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 64662.3
        )
    }
}
