import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional follow up rule must pass. Check returns its problems, or none.
    protocol RegionalFollowUpRuleRule {
        func check(_ item: RegionalFollowUpRule) -> [String]
    }

    final class RegionalFollowUpRuleRequiredNameRule: RegionalFollowUpRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalFollowUpRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalFollowUpRuleAllowedPhoneRule: RegionalFollowUpRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalFollowUpRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is too long"]
            }
            return []
        }
    }

    final class RegionalFollowUpRuleRequiredCodeRule: RegionalFollowUpRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalFollowUpRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalFollowUpRuleRequiredPhoneRule: RegionalFollowUpRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalFollowUpRule) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalFollowUpRuleCostRangeRule: RegionalFollowUpRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalFollowUpRule) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalFollowUpRuleNameLengthRule: RegionalFollowUpRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalFollowUpRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional follow up rule.
    final class RegionalFollowUpRuleValidator {
        var rules: [any RegionalFollowUpRuleRule]

        init(rules: [any RegionalFollowUpRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalFollowUpRule) -> [String] {
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

        func requireValid(_ item: RegionalFollowUpRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalFollowUpRule]) -> [String: [String]] {
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

    static func defaultRegionalFollowUpRuleValidator() -> RegionalFollowUpRuleValidator {
        return RegionalFollowUpRuleValidator(
            rules: [
                RegionalFollowUpRuleRequiredNameRule(message: "regional follow up rule needs an entry"),
                RegionalFollowUpRuleAllowedPhoneRule(allowed: ["capped", "legacy", "legacy"]),
                RegionalFollowUpRuleRequiredCodeRule(message: "regional follow up rule needs a value"),
                RegionalFollowUpRuleRequiredPhoneRule(message: "regional follow up rule needs an entry"),
                RegionalFollowUpRuleCostRangeRule(min: 9.3, max: 4012.6),
                RegionalFollowUpRuleNameLengthRule(maxLength: 86400),
            ]
        )
    }
}
