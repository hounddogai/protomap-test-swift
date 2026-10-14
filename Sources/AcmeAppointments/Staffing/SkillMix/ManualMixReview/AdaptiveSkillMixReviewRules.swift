import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive skill mix review must pass. Check returns its problems, or none.
    protocol AdaptiveSkillMixReviewRule {
        func check(_ item: AdaptiveSkillMixReview) -> [String]
    }

    final class AdaptiveSkillMixReviewRequiredDescriptionRule: AdaptiveSkillMixReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSkillMixReview) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSkillMixReviewRequiredDiagnosisCodeRule: AdaptiveSkillMixReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSkillMixReview) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSkillMixReviewAmountRangeRule: AdaptiveSkillMixReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveSkillMixReview) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveSkillMixReviewCodePrefixRule: AdaptiveSkillMixReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveSkillMixReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveSkillMixReviewCodeLengthRule: AdaptiveSkillMixReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveSkillMixReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveSkillMixReviewAllowedTimezoneRule: AdaptiveSkillMixReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveSkillMixReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive skill mix review.
    final class AdaptiveSkillMixReviewValidator {
        var rules: [any AdaptiveSkillMixReviewRule]

        init(rules: [any AdaptiveSkillMixReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveSkillMixReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveSkillMixReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveSkillMixReview]) -> [String: [String]] {
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

    static func defaultAdaptiveSkillMixReviewValidator() -> AdaptiveSkillMixReviewValidator {
        return AdaptiveSkillMixReviewValidator(
            rules: [
                AdaptiveSkillMixReviewRequiredDescriptionRule(message: "adaptive skill mix review needs a value"),
                AdaptiveSkillMixReviewRequiredDiagnosisCodeRule(message: "adaptive skill mix review needs this field"),
                AdaptiveSkillMixReviewAmountRangeRule(min: 1.5, max: 3049.0),
                AdaptiveSkillMixReviewCodePrefixRule(prefix: "X"),
                AdaptiveSkillMixReviewCodeLengthRule(maxLength: 32),
                AdaptiveSkillMixReviewAllowedTimezoneRule(allowed: ["global", "global"]),
            ]
        )
    }
}
