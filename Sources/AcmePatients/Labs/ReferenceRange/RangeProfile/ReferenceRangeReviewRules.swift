import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range review must pass. Check returns its problems, or none.
    protocol ReferenceRangeReviewRule {
        func check(_ item: ReferenceRangeReview) -> [String]
    }

    final class ReferenceRangeReviewRequiredOwnerIDRule: ReferenceRangeReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeReview) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeReviewCodePrefixRule: ReferenceRangeReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferenceRangeReviewNotesLengthRule: ReferenceRangeReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeReview) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range review.
    final class ReferenceRangeReviewValidator {
        var rules: [any ReferenceRangeReviewRule]

        init(rules: [any ReferenceRangeReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeReview]) -> [String: [String]] {
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

    static func defaultReferenceRangeReviewValidator() -> ReferenceRangeReviewValidator {
        return ReferenceRangeReviewValidator(
            rules: [
                ReferenceRangeReviewRequiredOwnerIDRule(message: "reference range review needs an entry"),
                ReferenceRangeReviewCodePrefixRule(prefix: "REF"),
                ReferenceRangeReviewNotesLengthRule(maxLength: 16),
            ]
        )
    }
}
