import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered risk score review must pass. Check returns its problems, or none.
    protocol TieredRiskScoreReviewRule {
        func check(_ item: TieredRiskScoreReview) -> [String]
    }

    final class TieredRiskScoreReviewTitleLengthRule: TieredRiskScoreReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRiskScoreReview) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRiskScoreReviewArchivedGuardRule: TieredRiskScoreReviewRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TieredRiskScoreReview) -> [String] {
            if item.archived && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class TieredRiskScoreReviewCodePrefixRule: TieredRiskScoreReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredRiskScoreReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredRiskScoreReviewRequiredUnitRule: TieredRiskScoreReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRiskScoreReview) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRiskScoreReviewMarginRangeRule: TieredRiskScoreReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRiskScoreReview) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredRiskScoreReviewUnitLengthRule: TieredRiskScoreReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRiskScoreReview) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered risk score review.
    final class TieredRiskScoreReviewValidator {
        var rules: [any TieredRiskScoreReviewRule]

        init(rules: [any TieredRiskScoreReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRiskScoreReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredRiskScoreReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRiskScoreReview]) -> [String: [String]] {
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

    static func defaultTieredRiskScoreReviewValidator() -> TieredRiskScoreReviewValidator {
        return TieredRiskScoreReviewValidator(
            rules: [
                TieredRiskScoreReviewTitleLengthRule(maxLength: 32),
                TieredRiskScoreReviewArchivedGuardRule(limit: 6.7),
                TieredRiskScoreReviewCodePrefixRule(prefix: "OPS"),
                TieredRiskScoreReviewRequiredUnitRule(message: "tiered risk score review needs a value"),
                TieredRiskScoreReviewMarginRangeRule(min: 7.1, max: 4697.5),
                TieredRiskScoreReviewUnitLengthRule(maxLength: 16),
            ]
        )
    }
}
