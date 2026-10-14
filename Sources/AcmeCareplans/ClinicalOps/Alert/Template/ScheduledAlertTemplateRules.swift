import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled alert template must pass. Check returns its problems, or none.
    protocol ScheduledAlertTemplateRule {
        func check(_ item: ScheduledAlertTemplate) -> [String]
    }

    final class ScheduledAlertTemplateActiveGuardRule: ScheduledAlertTemplateRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ScheduledAlertTemplate) -> [String] {
            if item.active && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ScheduledAlertTemplateRequiredLabelRule: ScheduledAlertTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAlertTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAlertTemplateRequiredCodeRule: ScheduledAlertTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAlertTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAlertTemplateRequiredFacilityRule: ScheduledAlertTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledAlertTemplate) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledAlertTemplateAllowedLabelRule: ScheduledAlertTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledAlertTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class ScheduledAlertTemplateLabelLengthRule: ScheduledAlertTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledAlertTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled alert template.
    final class ScheduledAlertTemplateValidator {
        var rules: [any ScheduledAlertTemplateRule]

        init(rules: [any ScheduledAlertTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledAlertTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledAlertTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledAlertTemplate]) -> [String: [String]] {
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

    static func defaultScheduledAlertTemplateValidator() -> ScheduledAlertTemplateValidator {
        return ScheduledAlertTemplateValidator(
            rules: [
                ScheduledAlertTemplateActiveGuardRule(limit: 0.4),
                ScheduledAlertTemplateRequiredLabelRule(message: "scheduled alert template needs a value"),
                ScheduledAlertTemplateRequiredCodeRule(message: "scheduled alert template needs a value"),
                ScheduledAlertTemplateRequiredFacilityRule(message: "scheduled alert template needs this field"),
                ScheduledAlertTemplateAllowedLabelRule(allowed: ["seasonal", "batched", "capped"]),
                ScheduledAlertTemplateLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
