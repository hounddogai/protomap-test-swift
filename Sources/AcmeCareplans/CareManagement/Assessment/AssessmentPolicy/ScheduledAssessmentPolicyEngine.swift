import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled assessment policy calculation.
    protocol ScheduledAssessmentPolicyStep {
        func describe() -> String
        func adjust(_ item: ScheduledAssessmentPolicy, value: Double) -> Double
    }

    final class FlaggedScheduledAssessmentPolicyAdjuster: ScheduledAssessmentPolicyStep {
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

        func adjust(_ item: ScheduledAssessmentPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleScheduledAssessmentPolicyAdjuster: ScheduledAssessmentPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ScheduledAssessmentPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ScheduledAssessmentPolicyRatioOffsetAdjuster: ScheduledAssessmentPolicyStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ScheduledAssessmentPolicy, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class PercentScheduledAssessmentPolicyAdjuster: ScheduledAssessmentPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledAssessmentPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled assessment policy steps in order and keeps a trace of each.
    final class ScheduledAssessmentPolicyEngine {
        var steps: [any ScheduledAssessmentPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAssessmentPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledAssessmentPolicy) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [ScheduledAssessmentPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledAssessmentPolicyEngine(_ flags: Kit.Flags.Registry) -> ScheduledAssessmentPolicyEngine {
        return ScheduledAssessmentPolicyEngine(
            steps: [
                FlaggedScheduledAssessmentPolicyAdjuster(
                    flags: flags,
                    flag: "scheduled-assessment-policy-capped",
                    percent: 8.1
                ),
                LocaleScheduledAssessmentPolicyAdjuster(factors: ["retail": 0.9, "west": 0.76, "online": 1.05]),
                ScheduledAssessmentPolicyRatioOffsetAdjuster(weight: 0.03),
                PercentScheduledAssessmentPolicyAdjuster(percent: -7.8),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 69370.2
        )
    }
}
