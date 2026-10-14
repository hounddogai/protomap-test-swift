import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling statement group must pass. Check returns its problems, or none.
    protocol RollingStatementGroupRule {
        func check(_ item: RollingStatementGroup) -> [String]
    }

    final class RollingStatementGroupVersionRangeRule: RollingStatementGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingStatementGroup) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingStatementGroupRequiredCodeRule: RollingStatementGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingStatementGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingStatementGroupWardLengthRule: RollingStatementGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingStatementGroup) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingStatementGroupRequiredCurrencyRule: RollingStatementGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingStatementGroup) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingStatementGroupCodeLengthRule: RollingStatementGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingStatementGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling statement group.
    final class RollingStatementGroupValidator {
        var rules: [any RollingStatementGroupRule]

        init(rules: [any RollingStatementGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingStatementGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingStatementGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingStatementGroup]) -> [String: [String]] {
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

    static func defaultRollingStatementGroupValidator() -> RollingStatementGroupValidator {
        return RollingStatementGroupValidator(
            rules: [
                RollingStatementGroupVersionRangeRule(min: 16, max: 3600),
                RollingStatementGroupRequiredCodeRule(message: "rolling statement group needs this field"),
                RollingStatementGroupWardLengthRule(maxLength: 16),
                RollingStatementGroupRequiredCurrencyRule(message: "rolling statement group needs an entry"),
                RollingStatementGroupCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
