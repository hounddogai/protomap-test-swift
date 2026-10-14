import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment target calculation.
    protocol AssessmentTargetStep {
        func describe() -> String
        func adjust(_ item: AssessmentTarget, value: Double) -> Double
    }

    final class CapAssessmentTargetAdjuster: AssessmentTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AssessmentTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AssessmentTargetBudgetOffsetAdjuster: AssessmentTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: AssessmentTarget, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class FlaggedAssessmentTargetAdjuster: AssessmentTargetStep {
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

        func adjust(_ item: AssessmentTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the assessment target steps in order and keeps a trace of each.
    final class AssessmentTargetEngine {
        var steps: [any AssessmentTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AssessmentTarget) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentTargetStep = steps[index]
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

        func evaluateAll(_ items: [AssessmentTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAssessmentTargetEngine(_ flags: Kit.Flags.Registry) -> AssessmentTargetEngine {
        return AssessmentTargetEngine(
            steps: [
                CapAssessmentTargetAdjuster(cap: 34109.0),
                AssessmentTargetBudgetOffsetAdjuster(weight: 0.7),
                FlaggedAssessmentTargetAdjuster(flags: flags, flag: "assessment-target-weighted", percent: 5.8),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 55304.7
        )
    }
}
