import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix metric must pass. Check returns its problems, or none.
    protocol SkillMixMetricRule {
        func check(_ item: SkillMixMetric) -> [String]
    }

    final class SkillMixMetricStartsAtRangeRule: SkillMixMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SkillMixMetric) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SkillMixMetricRequiredCategoryRule: SkillMixMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixMetric) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixMetricTitleLengthRule: SkillMixMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix metric.
    final class SkillMixMetricValidator {
        var rules: [any SkillMixMetricRule]

        init(rules: [any SkillMixMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixMetric) -> [String] {
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

        func requireValid(_ item: SkillMixMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixMetric]) -> [String: [String]] {
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

    static func defaultSkillMixMetricValidator() -> SkillMixMetricValidator {
        return SkillMixMetricValidator(
            rules: [
                SkillMixMetricStartsAtRangeRule(min: 32, max: 120),
                SkillMixMetricRequiredCategoryRule(message: "skill mix metric needs an entry"),
                SkillMixMetricTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
