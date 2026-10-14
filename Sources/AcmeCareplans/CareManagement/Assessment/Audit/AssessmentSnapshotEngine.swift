import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment snapshot calculation.
    protocol AssessmentSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: AssessmentSnapshot, value: Double) -> Double
    }

    final class FlaggedAssessmentSnapshotAdjuster: AssessmentSnapshotAdjuster {
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

        func adjust(_ item: AssessmentSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelAssessmentSnapshotAdjuster: AssessmentSnapshotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AssessmentSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAssessmentSnapshotAdjuster: AssessmentSnapshotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingAssessmentSnapshotAdjuster: AssessmentSnapshotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AssessmentSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AssessmentSnapshotAttemptsOffsetAdjuster: AssessmentSnapshotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: AssessmentSnapshot, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class CapAssessmentSnapshotAdjuster: AssessmentSnapshotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AssessmentSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the assessment snapshot steps in order and keeps a trace of each.
    final class AssessmentSnapshotEngine {
        var steps: [any AssessmentSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentSnapshot) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AssessmentSnapshotAdjuster = steps[index]
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

        func evaluateAll(_ items: [AssessmentSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentSnapshotEngine(_ flags: Kit.Flags.Registry) -> AssessmentSnapshotEngine {
        return AssessmentSnapshotEngine(
            steps: [
                FlaggedAssessmentSnapshotAdjuster(flags: flags, flag: "assessment-snapshot-adaptive", percent: -8.1),
                LabelAssessmentSnapshotAdjuster(factors: ["retail": 0.76]),
                MinimumAssessmentSnapshotAdjuster(minimum: 3.6),
                RoundingAssessmentSnapshotAdjuster(step: 1.0),
                AssessmentSnapshotAttemptsOffsetAdjuster(weight: 1.19),
                CapAssessmentSnapshotAdjuster(cap: 9285.0),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 64694.7
        )
    }
}
