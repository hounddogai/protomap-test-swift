import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure rule must pass. Check returns its problems, or none.
    protocol ClosureRuleRule {
        func check(_ item: ClosureRule) -> [String]
    }

    final class ClosureRuleLabelLengthRule: ClosureRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureRuleRequiredEncounterIDRule: ClosureRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureRule) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureRuleRequiredChannelRule: ClosureRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureRule) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a closure rule.
    final class ClosureRuleValidator {
        var rules: [any ClosureRuleRule]

        init(rules: [any ClosureRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureRule]) -> [String: [String]] {
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

    static func defaultClosureRuleValidator() -> ClosureRuleValidator {
        return ClosureRuleValidator(
            rules: [
                ClosureRuleLabelLengthRule(maxLength: 32),
                ClosureRuleRequiredEncounterIDRule(message: "closure rule needs a value"),
                ClosureRuleRequiredChannelRule(message: "closure rule needs this field"),
            ]
        )
    }
}
