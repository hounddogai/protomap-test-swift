import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled language rule must pass. Check returns its problems, or none.
    protocol ScheduledLanguageRuleRule {
        func check(_ item: ScheduledLanguageRule) -> [String]
    }

    final class ScheduledLanguageRuleCodeLengthRule: ScheduledLanguageRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledLanguageRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledLanguageRuleRequiredClinicianIDRule: ScheduledLanguageRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledLanguageRule) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledLanguageRuleLabelLengthRule: ScheduledLanguageRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledLanguageRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled language rule.
    final class ScheduledLanguageRuleValidator {
        var rules: [any ScheduledLanguageRuleRule]

        init(rules: [any ScheduledLanguageRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledLanguageRule) -> [String] {
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

        func requireValid(_ item: ScheduledLanguageRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledLanguageRule]) -> [String: [String]] {
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

    static func defaultScheduledLanguageRuleValidator() -> ScheduledLanguageRuleValidator {
        return ScheduledLanguageRuleValidator(
            rules: [
                ScheduledLanguageRuleCodeLengthRule(maxLength: 255),
                ScheduledLanguageRuleRequiredClinicianIDRule(message: "scheduled language rule needs this field"),
                ScheduledLanguageRuleLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
