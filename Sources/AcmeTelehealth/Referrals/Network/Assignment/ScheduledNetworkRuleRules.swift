import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled network rule must pass. Check returns its problems, or none.
    protocol ScheduledNetworkRuleRule {
        func check(_ item: ScheduledNetworkRule) -> [String]
    }

    final class ScheduledNetworkRuleTitleLengthRule: ScheduledNetworkRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledNetworkRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledNetworkRuleRequiredTitleRule: ScheduledNetworkRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledNetworkRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledNetworkRuleRequiredEncounterIDRule: ScheduledNetworkRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledNetworkRule) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledNetworkRuleEncounterIDLengthRule: ScheduledNetworkRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledNetworkRule) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledNetworkRuleCostRangeRule: ScheduledNetworkRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledNetworkRule) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled network rule.
    final class ScheduledNetworkRuleValidator {
        var rules: [any ScheduledNetworkRuleRule]

        init(rules: [any ScheduledNetworkRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledNetworkRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledNetworkRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledNetworkRule]) -> [String: [String]] {
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

    static func defaultScheduledNetworkRuleValidator() -> ScheduledNetworkRuleValidator {
        return ScheduledNetworkRuleValidator(
            rules: [
                ScheduledNetworkRuleTitleLengthRule(maxLength: 64),
                ScheduledNetworkRuleRequiredTitleRule(message: "scheduled network rule needs an entry"),
                ScheduledNetworkRuleRequiredEncounterIDRule(message: "scheduled network rule needs a value"),
                ScheduledNetworkRuleEncounterIDLengthRule(maxLength: 86400),
                ScheduledNetworkRuleCostRangeRule(min: 5.4, max: 632.5),
            ]
        )
    }
}
