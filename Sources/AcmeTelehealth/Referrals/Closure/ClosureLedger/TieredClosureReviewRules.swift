import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered closure review must pass. Check returns its problems, or none.
    protocol TieredClosureReviewRule {
        func check(_ item: TieredClosureReview) -> [String]
    }

    final class TieredClosureReviewRequiredNameRule: TieredClosureReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClosureReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredClosureReviewActiveGuardRule: TieredClosureReviewRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredClosureReview) -> [String] {
            if item.active && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class TieredClosureReviewCreatedAtRangeRule: TieredClosureReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredClosureReview) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredClosureReviewCodeLengthRule: TieredClosureReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClosureReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered closure review.
    final class TieredClosureReviewValidator {
        var rules: [any TieredClosureReviewRule]

        init(rules: [any TieredClosureReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredClosureReview) -> [String] {
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

        func requireValid(_ item: TieredClosureReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredClosureReview]) -> [String: [String]] {
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

    static func defaultTieredClosureReviewValidator() -> TieredClosureReviewValidator {
        return TieredClosureReviewValidator(
            rules: [
                TieredClosureReviewRequiredNameRule(message: "tiered closure review needs a value"),
                TieredClosureReviewActiveGuardRule(limit: 86400),
                TieredClosureReviewCreatedAtRangeRule(min: 32, max: 3600),
                TieredClosureReviewCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
