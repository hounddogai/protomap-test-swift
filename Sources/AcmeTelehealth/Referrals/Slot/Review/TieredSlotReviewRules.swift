import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered slot review must pass. Check returns its problems, or none.
    protocol TieredSlotReviewRule {
        func check(_ item: TieredSlotReview) -> [String]
    }

    final class TieredSlotReviewCopayRangeRule: TieredSlotReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredSlotReview) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredSlotReviewCodePrefixRule: TieredSlotReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredSlotReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredSlotReviewTitleLengthRule: TieredSlotReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSlotReview) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSlotReviewPriorityRangeRule: TieredSlotReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredSlotReview) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered slot review.
    final class TieredSlotReviewValidator {
        var rules: [any TieredSlotReviewRule]

        init(rules: [any TieredSlotReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredSlotReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredSlotReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredSlotReview]) -> [String: [String]] {
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

    static func defaultTieredSlotReviewValidator() -> TieredSlotReviewValidator {
        return TieredSlotReviewValidator(
            rules: [
                TieredSlotReviewCopayRangeRule(min: 0.4, max: 3590.6),
                TieredSlotReviewCodePrefixRule(prefix: "REF"),
                TieredSlotReviewTitleLengthRule(maxLength: 32),
                TieredSlotReviewPriorityRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
