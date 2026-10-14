import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive assessment assignment calculation.
    protocol AdaptiveAssessmentAssignmentFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveAssessmentAssignment, value: Double) -> Double
    }

    final class PercentAdaptiveAssessmentAssignmentAdjuster: AdaptiveAssessmentAssignmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveAssessmentAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AdaptiveAssessmentAssignmentQuantityOffsetAdjuster: AdaptiveAssessmentAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: AdaptiveAssessmentAssignment, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class FlaggedAdaptiveAssessmentAssignmentAdjuster: AdaptiveAssessmentAssignmentFactor {
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

        func adjust(_ item: AdaptiveAssessmentAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive assessment assignment steps in order and keeps a trace of each.
    final class AdaptiveAssessmentAssignmentEngine {
        var steps: [any AdaptiveAssessmentAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveAssessmentAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveAssessmentAssignment) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveAssessmentAssignmentFactor = steps[index]
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

        func evaluateAll(_ items: [AdaptiveAssessmentAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveAssessmentAssignmentEngine(_ flags: Kit.Flags.Registry) -> AdaptiveAssessmentAssignmentEngine {
        return AdaptiveAssessmentAssignmentEngine(
            steps: [
                PercentAdaptiveAssessmentAssignmentAdjuster(percent: 15.5),
                AdaptiveAssessmentAssignmentQuantityOffsetAdjuster(weight: 1.35),
                FlaggedAdaptiveAssessmentAssignmentAdjuster(
                    flags: flags,
                    flag: "adaptive-assessment-assignment-strict",
                    percent: 5.7
                ),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 99820.8
        )
    }
}
