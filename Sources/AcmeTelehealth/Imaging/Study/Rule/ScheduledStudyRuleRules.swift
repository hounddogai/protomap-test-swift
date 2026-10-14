import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled study rule must pass. Check returns its problems, or none.
    protocol ScheduledStudyRuleRule {
        func check(_ item: ScheduledStudyRule) -> [String]
    }

    final class ScheduledStudyRuleAllowedNameRule: ScheduledStudyRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledStudyRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    final class ScheduledStudyRuleRequiredCodeRule: ScheduledStudyRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledStudyRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledStudyRuleCodePrefixRule: ScheduledStudyRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledStudyRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledStudyRuleTitleLengthRule: ScheduledStudyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledStudyRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledStudyRuleFacilityLengthRule: ScheduledStudyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledStudyRule) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled study rule.
    final class ScheduledStudyRuleValidator {
        var rules: [any ScheduledStudyRuleRule]

        init(rules: [any ScheduledStudyRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledStudyRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledStudyRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledStudyRule]) -> [String: [String]] {
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

    static func defaultScheduledStudyRuleValidator() -> ScheduledStudyRuleValidator {
        return ScheduledStudyRuleValidator(
            rules: [
                ScheduledStudyRuleAllowedNameRule(allowed: ["seasonal"]),
                ScheduledStudyRuleRequiredCodeRule(message: "scheduled study rule needs this field"),
                ScheduledStudyRuleCodePrefixRule(prefix: "X"),
                ScheduledStudyRuleTitleLengthRule(maxLength: 86400),
                ScheduledStudyRuleFacilityLengthRule(maxLength: 32),
            ]
        )
    }
}
