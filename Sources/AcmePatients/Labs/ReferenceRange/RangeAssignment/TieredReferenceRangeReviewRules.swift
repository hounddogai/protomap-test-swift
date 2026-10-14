import AcmePlatform
import Foundation

extension Labs {
    /// A rule a tiered reference range review must pass. Check returns its problems, or none.
    protocol TieredReferenceRangeReviewRule {
        func check(_ item: TieredReferenceRangeReview) -> [String]
    }

    final class TieredReferenceRangeReviewRequiredCodeRule: TieredReferenceRangeReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReferenceRangeReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReferenceRangeReviewRequiredContactEmailRule: TieredReferenceRangeReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReferenceRangeReview) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReferenceRangeReviewApprovedGuardRule: TieredReferenceRangeReviewRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TieredReferenceRangeReview) -> [String] {
            if item.approved && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TieredReferenceRangeReviewRequiredLabelRule: TieredReferenceRangeReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReferenceRangeReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReferenceRangeReviewAllowedCodeRule: TieredReferenceRangeReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredReferenceRangeReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class TieredReferenceRangeReviewCodeLengthRule: TieredReferenceRangeReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferenceRangeReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered reference range review.
    final class TieredReferenceRangeReviewValidator {
        var rules: [any TieredReferenceRangeReviewRule]

        init(rules: [any TieredReferenceRangeReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReferenceRangeReview) -> [String] {
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

        func requireValid(_ item: TieredReferenceRangeReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReferenceRangeReview]) -> [String: [String]] {
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

    static func defaultTieredReferenceRangeReviewValidator() -> TieredReferenceRangeReviewValidator {
        return TieredReferenceRangeReviewValidator(
            rules: [
                TieredReferenceRangeReviewRequiredCodeRule(message: "tiered reference range review needs an entry"),
                TieredReferenceRangeReviewRequiredContactEmailRule(
                    message: "tiered reference range review needs this field"
                ),
                TieredReferenceRangeReviewApprovedGuardRule(limit: 7.3),
                TieredReferenceRangeReviewRequiredLabelRule(message: "tiered reference range review needs an entry"),
                TieredReferenceRangeReviewAllowedCodeRule(allowed: []),
                TieredReferenceRangeReviewCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
