import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling care protocol rule must pass. Check returns its problems, or none.
    protocol RollingCareProtocolRuleRule {
        func check(_ item: RollingCareProtocolRule) -> [String]
    }

    final class RollingCareProtocolRuleCodePrefixRule: RollingCareProtocolRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingCareProtocolRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingCareProtocolRuleWindowDaysRangeRule: RollingCareProtocolRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCareProtocolRule) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingCareProtocolRuleRequiredCurrencyRule: RollingCareProtocolRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCareProtocolRule) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling care protocol rule.
    final class RollingCareProtocolRuleValidator {
        var rules: [any RollingCareProtocolRuleRule]

        init(rules: [any RollingCareProtocolRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCareProtocolRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingCareProtocolRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCareProtocolRule]) -> [String: [String]] {
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

    static func defaultRollingCareProtocolRuleValidator() -> RollingCareProtocolRuleValidator {
        return RollingCareProtocolRuleValidator(
            rules: [
                RollingCareProtocolRuleCodePrefixRule(prefix: "ACM"),
                RollingCareProtocolRuleWindowDaysRangeRule(min: 120, max: 3600),
                RollingCareProtocolRuleRequiredCurrencyRule(message: "rolling care protocol rule needs an entry"),
            ]
        )
    }
}
