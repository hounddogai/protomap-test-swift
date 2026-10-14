import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement plan must pass. Check returns its problems, or none.
    protocol StatementPlanRule {
        func check(_ item: StatementPlan) -> [String]
    }

    final class StatementPlanRequiredChannelRule: StatementPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementPlan) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementPlanRequiredNameRule: StatementPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementPlan) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementPlanChannelLengthRule: StatementPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementPlan) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementPlanRequiredCodeRule: StatementPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a statement plan.
    final class StatementPlanValidator {
        var rules: [any StatementPlanRule]

        init(rules: [any StatementPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementPlan]) -> [String: [String]] {
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

    static func defaultStatementPlanValidator() -> StatementPlanValidator {
        return StatementPlanValidator(
            rules: [
                StatementPlanRequiredChannelRule(message: "statement plan needs an entry"),
                StatementPlanRequiredNameRule(message: "statement plan needs an entry"),
                StatementPlanChannelLengthRule(maxLength: 32),
                StatementPlanRequiredCodeRule(message: "statement plan needs an entry"),
            ]
        )
    }
}
