import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement review must pass. Check returns its problems, or none.
    protocol StatementReviewRule {
        func check(_ item: StatementReview) -> [String]
    }

    final class StatementReviewNameLengthRule: StatementReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementReviewRequiredNameRule: StatementReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementReviewCodeLengthRule: StatementReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementReviewAllowedTitleRule: StatementReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StatementReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a statement review.
    final class StatementReviewValidator {
        var rules: [any StatementReviewRule]

        init(rules: [any StatementReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementReview]) -> [String: [String]] {
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

    static func defaultStatementReviewValidator() -> StatementReviewValidator {
        return StatementReviewValidator(
            rules: [
                StatementReviewNameLengthRule(maxLength: 86400),
                StatementReviewRequiredNameRule(message: "statement review needs a value"),
                StatementReviewCodeLengthRule(maxLength: 32),
                StatementReviewAllowedTitleRule(allowed: []),
            ]
        )
    }
}
