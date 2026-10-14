import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up rule must pass. Check returns its problems, or none.
    protocol FollowUpRuleRule {
        func check(_ item: FollowUpRule) -> [String]
    }

    final class FollowUpRuleCodeLengthRule: FollowUpRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpRuleRequiredCountryRule: FollowUpRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpRule) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpRuleVersionRangeRule: FollowUpRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpRule) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a follow up rule.
    final class FollowUpRuleValidator {
        var rules: [any FollowUpRuleRule]

        init(rules: [any FollowUpRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpRule) -> [String] {
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

        func requireValid(_ item: FollowUpRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpRule]) -> [String: [String]] {
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

    static func defaultFollowUpRuleValidator() -> FollowUpRuleValidator {
        return FollowUpRuleValidator(
            rules: [
                FollowUpRuleCodeLengthRule(maxLength: 120),
                FollowUpRuleRequiredCountryRule(message: "follow up rule needs an entry"),
                FollowUpRuleVersionRangeRule(min: 3600, max: 3600),
            ]
        )
    }
}
