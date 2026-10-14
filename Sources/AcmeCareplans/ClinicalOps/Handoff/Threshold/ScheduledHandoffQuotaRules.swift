import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled handoff quota must pass. Check returns its problems, or none.
    protocol ScheduledHandoffQuotaRule {
        func check(_ item: ScheduledHandoffQuota) -> [String]
    }

    final class ScheduledHandoffQuotaRequiredLabelRule: ScheduledHandoffQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledHandoffQuota) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledHandoffQuotaBudgetRangeRule: ScheduledHandoffQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledHandoffQuota) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledHandoffQuotaRequiredPatientRefRule: ScheduledHandoffQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledHandoffQuota) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledHandoffQuotaAllowedPatientRefRule: ScheduledHandoffQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledHandoffQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is duplicated"]
            }
            return []
        }
    }

    final class ScheduledHandoffQuotaRequiredNameRule: ScheduledHandoffQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledHandoffQuota) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledHandoffQuotaFloorValueRangeRule: ScheduledHandoffQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledHandoffQuota) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled handoff quota.
    final class ScheduledHandoffQuotaValidator {
        var rules: [any ScheduledHandoffQuotaRule]

        init(rules: [any ScheduledHandoffQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledHandoffQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledHandoffQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledHandoffQuota]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultScheduledHandoffQuotaValidator() -> ScheduledHandoffQuotaValidator {
        return ScheduledHandoffQuotaValidator(
            rules: [
                ScheduledHandoffQuotaRequiredLabelRule(message: "scheduled handoff quota needs this field"),
                ScheduledHandoffQuotaBudgetRangeRule(min: 1.6, max: 3841.4),
                ScheduledHandoffQuotaRequiredPatientRefRule(message: "scheduled handoff quota needs this field"),
                ScheduledHandoffQuotaAllowedPatientRefRule(allowed: ["fallback", "tiered", "strict"]),
                ScheduledHandoffQuotaRequiredNameRule(message: "scheduled handoff quota needs a value"),
                ScheduledHandoffQuotaFloorValueRangeRule(min: 3.3, max: 3275.7),
            ]
        )
    }
}
