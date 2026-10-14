import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict skill mix review must pass. Check returns its problems, or none.
    protocol StrictSkillMixReviewRule {
        func check(_ item: StrictSkillMixReview) -> [String]
    }

    final class StrictSkillMixReviewRequiredNameRule: StrictSkillMixReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSkillMixReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSkillMixReviewNameLengthRule: StrictSkillMixReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSkillMixReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictSkillMixReviewCodePrefixRule: StrictSkillMixReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictSkillMixReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictSkillMixReviewRequiredCodeRule: StrictSkillMixReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSkillMixReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSkillMixReviewAllowedCodeRule: StrictSkillMixReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictSkillMixReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a strict skill mix review.
    final class StrictSkillMixReviewValidator {
        var rules: [any StrictSkillMixReviewRule]

        init(rules: [any StrictSkillMixReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSkillMixReview) -> [String] {
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

        func requireValid(_ item: StrictSkillMixReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSkillMixReview]) -> [String: [String]] {
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

    static func defaultStrictSkillMixReviewValidator() -> StrictSkillMixReviewValidator {
        return StrictSkillMixReviewValidator(
            rules: [
                StrictSkillMixReviewRequiredNameRule(message: "strict skill mix review needs this field"),
                StrictSkillMixReviewNameLengthRule(maxLength: 64),
                StrictSkillMixReviewCodePrefixRule(prefix: "OPS"),
                StrictSkillMixReviewRequiredCodeRule(message: "strict skill mix review needs this field"),
                StrictSkillMixReviewAllowedCodeRule(allowed: ["capped"]),
            ]
        )
    }
}
