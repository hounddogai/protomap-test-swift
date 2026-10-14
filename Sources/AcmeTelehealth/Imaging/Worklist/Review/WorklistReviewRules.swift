import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist review must pass. Check returns its problems, or none.
    protocol WorklistReviewRule {
        func check(_ item: WorklistReview) -> [String]
    }

    final class WorklistReviewOwnerIDLengthRule: WorklistReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistReview) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistReviewCodePrefixRule: WorklistReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WorklistReviewRequiredOwnerIDRule: WorklistReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistReview) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistReviewCodeLengthRule: WorklistReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist review.
    final class WorklistReviewValidator {
        var rules: [any WorklistReviewRule]

        init(rules: [any WorklistReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistReview) -> [String] {
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

        func requireValid(_ item: WorklistReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistReview]) -> [String: [String]] {
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

    static func defaultWorklistReviewValidator() -> WorklistReviewValidator {
        return WorklistReviewValidator(
            rules: [
                WorklistReviewOwnerIDLengthRule(maxLength: 3600),
                WorklistReviewCodePrefixRule(prefix: "X"),
                WorklistReviewRequiredOwnerIDRule(message: "worklist review needs a value"),
                WorklistReviewCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
