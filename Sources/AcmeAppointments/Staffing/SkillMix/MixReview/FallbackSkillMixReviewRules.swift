import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback skill mix review must pass. Check returns its problems, or none.
    protocol FallbackSkillMixReviewRule {
        func check(_ item: FallbackSkillMixReview) -> [String]
    }

    final class FallbackSkillMixReviewNameLengthRule: FallbackSkillMixReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackSkillMixReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackSkillMixReviewRefillsRangeRule: FallbackSkillMixReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackSkillMixReview) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackSkillMixReviewCodePrefixRule: FallbackSkillMixReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackSkillMixReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback skill mix review.
    final class FallbackSkillMixReviewValidator {
        var rules: [any FallbackSkillMixReviewRule]

        init(rules: [any FallbackSkillMixReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackSkillMixReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackSkillMixReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackSkillMixReview]) -> [String: [String]] {
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

    static func defaultFallbackSkillMixReviewValidator() -> FallbackSkillMixReviewValidator {
        return FallbackSkillMixReviewValidator(
            rules: [
                FallbackSkillMixReviewNameLengthRule(maxLength: 80),
                FallbackSkillMixReviewRefillsRangeRule(min: 120, max: 86400),
                FallbackSkillMixReviewCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
