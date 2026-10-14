import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix estimate must pass. Check returns its problems, or none.
    protocol SkillMixEstimateRule {
        func check(_ item: SkillMixEstimate) -> [String]
    }

    final class SkillMixEstimateRequiredTitleRule: SkillMixEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixEstimateRequiredContactEmailRule: SkillMixEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixEstimate) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixEstimateCodePrefixRule: SkillMixEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SkillMixEstimateDescriptionLengthRule: SkillMixEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixEstimate) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixEstimateRequiredCodeRule: SkillMixEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixEstimateScoreRangeRule: SkillMixEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixEstimate) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a skill mix estimate.
    final class SkillMixEstimateValidator {
        var rules: [any SkillMixEstimateRule]

        init(rules: [any SkillMixEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixEstimate) -> [String] {
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

        func requireValid(_ item: SkillMixEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixEstimate]) -> [String: [String]] {
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

    static func defaultSkillMixEstimateValidator() -> SkillMixEstimateValidator {
        return SkillMixEstimateValidator(
            rules: [
                SkillMixEstimateRequiredTitleRule(message: "skill mix estimate needs a value"),
                SkillMixEstimateRequiredContactEmailRule(message: "skill mix estimate needs this field"),
                SkillMixEstimateCodePrefixRule(prefix: "ACM"),
                SkillMixEstimateDescriptionLengthRule(maxLength: 32),
                SkillMixEstimateRequiredCodeRule(message: "skill mix estimate needs an entry"),
                SkillMixEstimateScoreRangeRule(min: 9.4, max: 2308.5),
            ]
        )
    }
}
