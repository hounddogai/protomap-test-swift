import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a rolling goal template must pass. Check returns its problems, or none.
    protocol RollingGoalTemplateRule {
        func check(_ item: RollingGoalTemplate) -> [String]
    }

    final class RollingGoalTemplateAllowedOwnerIDRule: RollingGoalTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingGoalTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is unknown"]
            }
            return []
        }
    }

    final class RollingGoalTemplateLabelLengthRule: RollingGoalTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingGoalTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingGoalTemplateCodePrefixRule: RollingGoalTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingGoalTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingGoalTemplateRequiredOwnerIDRule: RollingGoalTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingGoalTemplate) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling goal template.
    final class RollingGoalTemplateValidator {
        var rules: [any RollingGoalTemplateRule]

        init(rules: [any RollingGoalTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingGoalTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingGoalTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingGoalTemplate]) -> [String: [String]] {
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

    static func defaultRollingGoalTemplateValidator() -> RollingGoalTemplateValidator {
        return RollingGoalTemplateValidator(
            rules: [
                RollingGoalTemplateAllowedOwnerIDRule(allowed: ["regional"]),
                RollingGoalTemplateLabelLengthRule(maxLength: 3600),
                RollingGoalTemplateCodePrefixRule(prefix: "X"),
                RollingGoalTemplateRequiredOwnerIDRule(message: "rolling goal template needs an entry"),
            ]
        )
    }
}
