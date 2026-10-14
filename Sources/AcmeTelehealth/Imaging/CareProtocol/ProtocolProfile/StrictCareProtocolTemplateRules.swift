import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict care protocol template must pass. Check returns its problems, or none.
    protocol StrictCareProtocolTemplateRule {
        func check(_ item: StrictCareProtocolTemplate) -> [String]
    }

    final class StrictCareProtocolTemplateRequiredSummaryRule: StrictCareProtocolTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCareProtocolTemplate) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCareProtocolTemplateDosageMgRangeRule: StrictCareProtocolTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictCareProtocolTemplate) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictCareProtocolTemplateLabelLengthRule: StrictCareProtocolTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictCareProtocolTemplate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict care protocol template.
    final class StrictCareProtocolTemplateValidator {
        var rules: [any StrictCareProtocolTemplateRule]

        init(rules: [any StrictCareProtocolTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictCareProtocolTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictCareProtocolTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictCareProtocolTemplate]) -> [String: [String]] {
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

    static func defaultStrictCareProtocolTemplateValidator() -> StrictCareProtocolTemplateValidator {
        return StrictCareProtocolTemplateValidator(
            rules: [
                StrictCareProtocolTemplateRequiredSummaryRule(
                    message: "strict care protocol template needs this field"
                ),
                StrictCareProtocolTemplateDosageMgRangeRule(min: 9.1, max: 3776.0),
                StrictCareProtocolTemplateLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
