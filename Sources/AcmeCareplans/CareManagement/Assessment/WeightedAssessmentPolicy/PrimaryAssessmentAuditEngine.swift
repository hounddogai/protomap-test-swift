import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the primary assessment audit calculation.
    protocol PrimaryAssessmentAuditModifier {
        func describe() -> String
        func adjust(_ item: PrimaryAssessmentAudit, value: Double) -> Double
    }

    final class MinimumPrimaryAssessmentAuditAdjuster: PrimaryAssessmentAuditModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryAssessmentAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PrimaryAssessmentAuditRetriesOffsetAdjuster: PrimaryAssessmentAuditModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: PrimaryAssessmentAudit, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class FlaggedPrimaryAssessmentAuditAdjuster: PrimaryAssessmentAuditModifier {
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

        func adjust(_ item: PrimaryAssessmentAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPrimaryAssessmentAuditAdjuster: PrimaryAssessmentAuditModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryAssessmentAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityPrimaryAssessmentAuditAdjuster: PrimaryAssessmentAuditModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: PrimaryAssessmentAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary assessment audit steps in order and keeps a trace of each.
    final class PrimaryAssessmentAuditEngine {
        var steps: [any PrimaryAssessmentAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryAssessmentAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryAssessmentAudit) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [PrimaryAssessmentAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryAssessmentAuditEngine(_ flags: Kit.Flags.Registry) -> PrimaryAssessmentAuditEngine {
        return PrimaryAssessmentAuditEngine(
            steps: [
                MinimumPrimaryAssessmentAuditAdjuster(minimum: 25.7),
                PrimaryAssessmentAuditRetriesOffsetAdjuster(weight: 0.25),
                FlaggedPrimaryAssessmentAuditAdjuster(
                    flags: flags,
                    flag: "primary-assessment-audit-strict",
                    percent: -7.7
                ),
                PercentPrimaryAssessmentAuditAdjuster(percent: -4.1),
                FacilityPrimaryAssessmentAuditAdjuster(factors: ["retail": 0.72, "central": 0.91]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 19398.4
        )
    }
}
