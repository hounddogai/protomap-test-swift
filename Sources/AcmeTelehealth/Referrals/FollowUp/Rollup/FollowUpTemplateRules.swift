import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up template must pass. Check returns its problems, or none.
    protocol FollowUpTemplateRule {
        func check(_ item: FollowUpTemplate) -> [String]
    }

    final class FollowUpTemplateAllowedDescriptionRule: FollowUpTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FollowUpTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is expired"]
            }
            return []
        }
    }

    final class FollowUpTemplateDescriptionLengthRule: FollowUpTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpTemplate) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpTemplateLabelLengthRule: FollowUpTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up template.
    final class FollowUpTemplateValidator {
        var rules: [any FollowUpTemplateRule]

        init(rules: [any FollowUpTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpTemplate) -> [String] {
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

        func requireValid(_ item: FollowUpTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpTemplate]) -> [String: [String]] {
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

    static func defaultFollowUpTemplateValidator() -> FollowUpTemplateValidator {
        return FollowUpTemplateValidator(
            rules: [
                FollowUpTemplateAllowedDescriptionRule(allowed: ["lenient"]),
                FollowUpTemplateDescriptionLengthRule(maxLength: 255),
                FollowUpTemplateLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
