import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime template must pass. Check returns its problems, or none.
    protocol OvertimeTemplateRule {
        func check(_ item: OvertimeTemplate) -> [String]
    }

    final class OvertimeTemplateRequiredRegionRule: OvertimeTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeTemplate) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeTemplateTitleLengthRule: OvertimeTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeTemplateRateRangeRule: OvertimeTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeTemplate) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OvertimeTemplateDosageMgRangeRule: OvertimeTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeTemplate) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OvertimeTemplateCodeLengthRule: OvertimeTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime template.
    final class OvertimeTemplateValidator {
        var rules: [any OvertimeTemplateRule]

        init(rules: [any OvertimeTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeTemplate]) -> [String: [String]] {
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

    static func defaultOvertimeTemplateValidator() -> OvertimeTemplateValidator {
        return OvertimeTemplateValidator(
            rules: [
                OvertimeTemplateRequiredRegionRule(message: "overtime template needs a value"),
                OvertimeTemplateTitleLengthRule(maxLength: 1000),
                OvertimeTemplateRateRangeRule(min: 2.7, max: 1164.7),
                OvertimeTemplateDosageMgRangeRule(min: 9.7, max: 247.2),
                OvertimeTemplateCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
