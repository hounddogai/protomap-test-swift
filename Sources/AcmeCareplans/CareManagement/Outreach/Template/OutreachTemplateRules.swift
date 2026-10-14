import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach template must pass. Check returns its problems, or none.
    protocol OutreachTemplateRule {
        func check(_ item: OutreachTemplate) -> [String]
    }

    final class OutreachTemplateRequiredLabelRule: OutreachTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachTemplateCategoryLengthRule: OutreachTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachTemplate) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachTemplateActiveGuardRule: OutreachTemplateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: OutreachTemplate) -> [String] {
            if item.active && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class OutreachTemplateRevisionRangeRule: OutreachTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachTemplate) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachTemplateRequiredTitleRule: OutreachTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachTemplate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachTemplateTitleLengthRule: OutreachTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach template.
    final class OutreachTemplateValidator {
        var rules: [any OutreachTemplateRule]

        init(rules: [any OutreachTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachTemplate) -> [String] {
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

        func requireValid(_ item: OutreachTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachTemplate]) -> [String: [String]] {
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

    static func defaultOutreachTemplateValidator() -> OutreachTemplateValidator {
        return OutreachTemplateValidator(
            rules: [
                OutreachTemplateRequiredLabelRule(message: "outreach template needs a value"),
                OutreachTemplateCategoryLengthRule(maxLength: 80),
                OutreachTemplateActiveGuardRule(limit: 86400),
                OutreachTemplateRevisionRangeRule(min: 16, max: 64),
                OutreachTemplateRequiredTitleRule(message: "outreach template needs an entry"),
                OutreachTemplateTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
