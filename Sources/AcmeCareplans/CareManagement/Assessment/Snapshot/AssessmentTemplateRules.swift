import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment template must pass. Check returns its problems, or none.
    protocol AssessmentTemplateRule {
        func check(_ item: AssessmentTemplate) -> [String]
    }

    final class AssessmentTemplateNameLengthRule: AssessmentTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentTemplateCodeLengthRule: AssessmentTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentTemplateLimitRangeRule: AssessmentTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentTemplate) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AssessmentTemplateRequiredFacilityRule: AssessmentTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentTemplate) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentTemplateFacilityLengthRule: AssessmentTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentTemplate) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment template.
    final class AssessmentTemplateValidator {
        var rules: [any AssessmentTemplateRule]

        init(rules: [any AssessmentTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentTemplate) -> [String] {
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

        func requireValid(_ item: AssessmentTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentTemplate]) -> [String: [String]] {
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

    static func defaultAssessmentTemplateValidator() -> AssessmentTemplateValidator {
        return AssessmentTemplateValidator(
            rules: [
                AssessmentTemplateNameLengthRule(maxLength: 16),
                AssessmentTemplateCodeLengthRule(maxLength: 3600),
                AssessmentTemplateLimitRangeRule(min: 32, max: 1000),
                AssessmentTemplateRequiredFacilityRule(message: "assessment template needs an entry"),
                AssessmentTemplateFacilityLengthRule(maxLength: 1000),
            ]
        )
    }
}
