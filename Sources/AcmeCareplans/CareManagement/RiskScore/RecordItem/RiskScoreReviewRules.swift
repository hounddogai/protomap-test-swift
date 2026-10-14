import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score review must pass. Check returns its problems, or none.
    protocol RiskScoreReviewRule {
        func check(_ item: RiskScoreReview) -> [String]
    }

    final class RiskScoreReviewRequiredCodeRule: RiskScoreReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreReviewCodeLengthRule: RiskScoreReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreReviewRequiredUnitRule: RiskScoreReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreReview) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreReviewAllowedCodeRule: RiskScoreReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class RiskScoreReviewNameLengthRule: RiskScoreReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreReviewThresholdRangeRule: RiskScoreReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreReview) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a risk score review.
    final class RiskScoreReviewValidator {
        var rules: [any RiskScoreReviewRule]

        init(rules: [any RiskScoreReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreReview]) -> [String: [String]] {
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

    static func defaultRiskScoreReviewValidator() -> RiskScoreReviewValidator {
        return RiskScoreReviewValidator(
            rules: [
                RiskScoreReviewRequiredCodeRule(message: "risk score review needs a value"),
                RiskScoreReviewCodeLengthRule(maxLength: 3600),
                RiskScoreReviewRequiredUnitRule(message: "risk score review needs a value"),
                RiskScoreReviewAllowedCodeRule(allowed: []),
                RiskScoreReviewNameLengthRule(maxLength: 32),
                RiskScoreReviewThresholdRangeRule(min: 3.4, max: 1491.4),
            ]
        )
    }
}
