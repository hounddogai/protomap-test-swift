import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled census rule must pass. Check returns its problems, or none.
    protocol ScheduledCensusRuleRule {
        func check(_ item: ScheduledCensusRule) -> [String]
    }

    final class ScheduledCensusRuleRequiredTitleRule: ScheduledCensusRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCensusRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCensusRuleCodeLengthRule: ScheduledCensusRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCensusRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCensusRuleCodePrefixRule: ScheduledCensusRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledCensusRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled census rule.
    final class ScheduledCensusRuleValidator {
        var rules: [any ScheduledCensusRuleRule]

        init(rules: [any ScheduledCensusRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCensusRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCensusRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCensusRule]) -> [String: [String]] {
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

    static func defaultScheduledCensusRuleValidator() -> ScheduledCensusRuleValidator {
        return ScheduledCensusRuleValidator(
            rules: [
                ScheduledCensusRuleRequiredTitleRule(message: "scheduled census rule needs this field"),
                ScheduledCensusRuleCodeLengthRule(maxLength: 64),
                ScheduledCensusRuleCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
