import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the legacy assessment milestone calculation.
    protocol LegacyAssessmentMilestoneFactor {
        func describe() -> String
        func adjust(_ item: LegacyAssessmentMilestone, value: Double) -> Double
    }

    final class MinimumLegacyAssessmentMilestoneAdjuster: LegacyAssessmentMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyAssessmentMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLegacyAssessmentMilestoneAdjuster: LegacyAssessmentMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyAssessmentMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLegacyAssessmentMilestoneAdjuster: LegacyAssessmentMilestoneFactor {
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

        func adjust(_ item: LegacyAssessmentMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy assessment milestone steps in order and keeps a trace of each.
    final class LegacyAssessmentMilestoneEngine {
        var steps: [any LegacyAssessmentMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAssessmentMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyAssessmentMilestone) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [LegacyAssessmentMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyAssessmentMilestoneEngine(_ flags: Kit.Flags.Registry) -> LegacyAssessmentMilestoneEngine {
        return LegacyAssessmentMilestoneEngine(
            steps: [
                MinimumLegacyAssessmentMilestoneAdjuster(minimum: 33.9),
                PercentLegacyAssessmentMilestoneAdjuster(percent: 12.7),
                FlaggedLegacyAssessmentMilestoneAdjuster(
                    flags: flags,
                    flag: "legacy-assessment-milestone-global",
                    percent: 0.9
                ),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 53255.2
        )
    }
}
