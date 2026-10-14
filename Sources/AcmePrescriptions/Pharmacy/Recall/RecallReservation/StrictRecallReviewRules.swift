import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a strict recall review must pass. Check returns its problems, or none.
    protocol StrictRecallReviewRule {
        func check(_ item: StrictRecallReview) -> [String]
    }

    final class StrictRecallReviewCodePrefixRule: StrictRecallReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictRecallReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictRecallReviewDosageMgRangeRule: StrictRecallReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictRecallReview) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictRecallReviewAllowedSummaryRule: StrictRecallReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictRecallReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is too long"]
            }
            return []
        }
    }

    final class StrictRecallReviewRequiredSummaryRule: StrictRecallReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictRecallReview) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictRecallReviewSummaryLengthRule: StrictRecallReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRecallReview) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictRecallReviewEndsAtRangeRule: StrictRecallReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictRecallReview) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a strict recall review.
    final class StrictRecallReviewValidator {
        var rules: [any StrictRecallReviewRule]

        init(rules: [any StrictRecallReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictRecallReview) -> [String] {
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

        func requireValid(_ item: StrictRecallReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictRecallReview]) -> [String: [String]] {
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

    static func defaultStrictRecallReviewValidator() -> StrictRecallReviewValidator {
        return StrictRecallReviewValidator(
            rules: [
                StrictRecallReviewCodePrefixRule(prefix: "OPS"),
                StrictRecallReviewDosageMgRangeRule(min: 4.0, max: 3346.1),
                StrictRecallReviewAllowedSummaryRule(allowed: ["tiered"]),
                StrictRecallReviewRequiredSummaryRule(message: "strict recall review needs this field"),
                StrictRecallReviewSummaryLengthRule(maxLength: 255),
                StrictRecallReviewEndsAtRangeRule(min: 86400, max: 86400),
            ]
        )
    }
}
