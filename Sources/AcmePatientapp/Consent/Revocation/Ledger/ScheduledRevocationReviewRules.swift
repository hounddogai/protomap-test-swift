import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled revocation review must pass. Check returns its problems, or none.
    protocol ScheduledRevocationReviewRule {
        func check(_ item: ScheduledRevocationReview) -> [String]
    }

    final class ScheduledRevocationReviewAllowedProcedureCodeRule: ScheduledRevocationReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledRevocationReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is stale"]
            }
            return []
        }
    }

    final class ScheduledRevocationReviewCodePrefixRule: ScheduledRevocationReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledRevocationReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledRevocationReviewRequiredCodeRule: ScheduledRevocationReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRevocationReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledRevocationReviewRequiredProcedureCodeRule: ScheduledRevocationReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRevocationReview) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledRevocationReviewLabelLengthRule: ScheduledRevocationReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledRevocationReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledRevocationReviewCodeLengthRule: ScheduledRevocationReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledRevocationReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled revocation review.
    final class ScheduledRevocationReviewValidator {
        var rules: [any ScheduledRevocationReviewRule]

        init(rules: [any ScheduledRevocationReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledRevocationReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledRevocationReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledRevocationReview]) -> [String: [String]] {
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

    static func defaultScheduledRevocationReviewValidator() -> ScheduledRevocationReviewValidator {
        return ScheduledRevocationReviewValidator(
            rules: [
                ScheduledRevocationReviewAllowedProcedureCodeRule(allowed: []),
                ScheduledRevocationReviewCodePrefixRule(prefix: "ACM"),
                ScheduledRevocationReviewRequiredCodeRule(message: "scheduled revocation review needs a value"),
                ScheduledRevocationReviewRequiredProcedureCodeRule(
                    message: "scheduled revocation review needs this field"
                ),
                ScheduledRevocationReviewLabelLengthRule(maxLength: 80),
                ScheduledRevocationReviewCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
