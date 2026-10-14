import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the primary assessment checkpoint calculation.
    protocol PrimaryAssessmentCheckpointFactor {
        func describe() -> String
        func adjust(_ item: PrimaryAssessmentCheckpoint, value: Double) -> Double
    }

    final class FlaggedPrimaryAssessmentCheckpointAdjuster: PrimaryAssessmentCheckpointFactor {
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

        func adjust(_ item: PrimaryAssessmentCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryAssessmentCheckpointAdjuster: PrimaryAssessmentCheckpointFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryAssessmentCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPrimaryAssessmentCheckpointAdjuster: PrimaryAssessmentCheckpointFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryAssessmentCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary assessment checkpoint steps in order and keeps a trace of each.
    final class PrimaryAssessmentCheckpointEngine {
        var steps: [any PrimaryAssessmentCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryAssessmentCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryAssessmentCheckpoint) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [PrimaryAssessmentCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryAssessmentCheckpointEngine(_ flags: Kit.Flags.Registry) -> PrimaryAssessmentCheckpointEngine {
        return PrimaryAssessmentCheckpointEngine(
            steps: [
                FlaggedPrimaryAssessmentCheckpointAdjuster(
                    flags: flags,
                    flag: "primary-assessment-checkpoint-primary",
                    percent: 4.1
                ),
                RoundingPrimaryAssessmentCheckpointAdjuster(step: 0.1),
                MinimumPrimaryAssessmentCheckpointAdjuster(minimum: 34.1),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 21198.6
        )
    }
}
