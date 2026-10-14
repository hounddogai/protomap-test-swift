import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending statement target must pass. Check returns its problems, or none.
    protocol PendingStatementTargetRule {
        func check(_ item: PendingStatementTarget) -> [String]
    }

    final class PendingStatementTargetBudgetRangeRule: PendingStatementTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingStatementTarget) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingStatementTargetRequiredCodeRule: PendingStatementTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingStatementTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingStatementTargetNameLengthRule: PendingStatementTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingStatementTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending statement target.
    final class PendingStatementTargetValidator {
        var rules: [any PendingStatementTargetRule]

        init(rules: [any PendingStatementTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingStatementTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingStatementTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingStatementTarget]) -> [String: [String]] {
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

    static func defaultPendingStatementTargetValidator() -> PendingStatementTargetValidator {
        return PendingStatementTargetValidator(
            rules: [
                PendingStatementTargetBudgetRangeRule(min: 4.3, max: 3358.9),
                PendingStatementTargetRequiredCodeRule(message: "pending statement target needs an entry"),
                PendingStatementTargetNameLengthRule(maxLength: 16),
            ]
        )
    }
}
