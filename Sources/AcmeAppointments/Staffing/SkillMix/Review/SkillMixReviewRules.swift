import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix review must pass. Check returns its problems, or none.
    protocol SkillMixReviewRule {
        func check(_ item: SkillMixReview) -> [String]
    }

    final class SkillMixReviewAttemptsRangeRule: SkillMixReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixReview) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixReviewRequiredCodeRule: SkillMixReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixReviewAllowedBedRule: SkillMixReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SkillMixReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is above maximum"]
            }
            return []
        }
    }

    final class SkillMixReviewVisitMinutesRangeRule: SkillMixReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixReview) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixReviewCodePrefixRule: SkillMixReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix review.
    final class SkillMixReviewValidator {
        var rules: [any SkillMixReviewRule]

        init(rules: [any SkillMixReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixReview]) -> [String: [String]] {
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

    static func defaultSkillMixReviewValidator() -> SkillMixReviewValidator {
        return SkillMixReviewValidator(
            rules: [
                SkillMixReviewAttemptsRangeRule(min: 80, max: 255),
                SkillMixReviewRequiredCodeRule(message: "skill mix review needs an entry"),
                SkillMixReviewAllowedBedRule(allowed: []),
                SkillMixReviewVisitMinutesRangeRule(min: 64, max: 86400),
                SkillMixReviewCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
