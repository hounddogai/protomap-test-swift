import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession template must pass. Check returns its problems, or none.
    protocol AccessionTemplateRule {
        func check(_ item: AccessionTemplate) -> [String]
    }

    final class AccessionTemplateDurationMinutesRangeRule: AccessionTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionTemplate) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionTemplateRequiredContactEmailRule: AccessionTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionTemplate) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionTemplateTitleLengthRule: AccessionTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession template.
    final class AccessionTemplateValidator {
        var rules: [any AccessionTemplateRule]

        init(rules: [any AccessionTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionTemplate]) -> [String: [String]] {
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

    static func defaultAccessionTemplateValidator() -> AccessionTemplateValidator {
        return AccessionTemplateValidator(
            rules: [
                AccessionTemplateDurationMinutesRangeRule(min: 120, max: 255),
                AccessionTemplateRequiredContactEmailRule(message: "accession template needs a value"),
                AccessionTemplateTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
