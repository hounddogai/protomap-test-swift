import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility template must pass. Check returns its problems, or none.
    protocol EligibilityTemplateRule {
        func check(_ item: EligibilityTemplate) -> [String]
    }

    final class EligibilityTemplatePinnedGuardRule: EligibilityTemplateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: EligibilityTemplate) -> [String] {
            if item.pinned && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class EligibilityTemplateCodeLengthRule: EligibilityTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityTemplateRequiredSummaryRule: EligibilityTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityTemplate) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility template.
    final class EligibilityTemplateValidator {
        var rules: [any EligibilityTemplateRule]

        init(rules: [any EligibilityTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityTemplate) -> [String] {
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

        func requireValid(_ item: EligibilityTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityTemplate]) -> [String: [String]] {
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

    static func defaultEligibilityTemplateValidator() -> EligibilityTemplateValidator {
        return EligibilityTemplateValidator(
            rules: [
                EligibilityTemplatePinnedGuardRule(limit: 120),
                EligibilityTemplateCodeLengthRule(maxLength: 120),
                EligibilityTemplateRequiredSummaryRule(message: "eligibility template needs a value"),
            ]
        )
    }
}
