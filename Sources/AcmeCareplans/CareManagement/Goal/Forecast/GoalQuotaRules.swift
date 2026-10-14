import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal quota must pass. Check returns its problems, or none.
    protocol GoalQuotaRule {
        func check(_ item: GoalQuota) -> [String]
    }

    final class GoalQuotaRequiredCodeRule: GoalQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalQuotaAllowedLocaleRule: GoalQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GoalQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is not allowed"]
            }
            return []
        }
    }

    final class GoalQuotaLocaleLengthRule: GoalQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalQuota) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalQuotaRequiredLabelRule: GoalQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalQuota) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalQuotaRequiredLocaleRule: GoalQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalQuota) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a goal quota.
    final class GoalQuotaValidator {
        var rules: [any GoalQuotaRule]

        init(rules: [any GoalQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: GoalQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalQuota]) -> [String: [String]] {
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

    static func defaultGoalQuotaValidator() -> GoalQuotaValidator {
        return GoalQuotaValidator(
            rules: [
                GoalQuotaRequiredCodeRule(message: "goal quota needs this field"),
                GoalQuotaAllowedLocaleRule(allowed: ["weighted", "primary", "strict"]),
                GoalQuotaLocaleLengthRule(maxLength: 86400),
                GoalQuotaRequiredLabelRule(message: "goal quota needs an entry"),
                GoalQuotaRequiredLocaleRule(message: "goal quota needs this field"),
            ]
        )
    }
}
