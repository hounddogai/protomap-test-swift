import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a legacy claim budget must pass. Check returns its problems, or none.
    protocol LegacyClaimBudgetRule {
        func check(_ item: LegacyClaimBudget) -> [String]
    }

    final class LegacyClaimBudgetRequiredTitleRule: LegacyClaimBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyClaimBudget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyClaimBudgetWardLengthRule: LegacyClaimBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyClaimBudget) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyClaimBudgetReviewerLengthRule: LegacyClaimBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyClaimBudget) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyClaimBudgetRequiredReviewerRule: LegacyClaimBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyClaimBudget) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy claim budget.
    final class LegacyClaimBudgetValidator {
        var rules: [any LegacyClaimBudgetRule]

        init(rules: [any LegacyClaimBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyClaimBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyClaimBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyClaimBudget]) -> [String: [String]] {
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

    static func defaultLegacyClaimBudgetValidator() -> LegacyClaimBudgetValidator {
        return LegacyClaimBudgetValidator(
            rules: [
                LegacyClaimBudgetRequiredTitleRule(message: "legacy claim budget needs a value"),
                LegacyClaimBudgetWardLengthRule(maxLength: 80),
                LegacyClaimBudgetReviewerLengthRule(maxLength: 3600),
                LegacyClaimBudgetRequiredReviewerRule(message: "legacy claim budget needs a value"),
            ]
        )
    }
}
