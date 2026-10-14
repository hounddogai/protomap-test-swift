import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding template must pass. Check returns its problems, or none.
    protocol RoundingTemplateRule {
        func check(_ item: RoundingTemplate) -> [String]
    }

    final class RoundingTemplateAcuityRangeRule: RoundingTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingTemplate) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingTemplateRequiredLocaleRule: RoundingTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingTemplate) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingTemplateRequiredPatientRefRule: RoundingTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingTemplate) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rounding template.
    final class RoundingTemplateValidator {
        var rules: [any RoundingTemplateRule]

        init(rules: [any RoundingTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingTemplate) -> [String] {
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

        func requireValid(_ item: RoundingTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingTemplate]) -> [String: [String]] {
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

    static func defaultRoundingTemplateValidator() -> RoundingTemplateValidator {
        return RoundingTemplateValidator(
            rules: [
                RoundingTemplateAcuityRangeRule(min: 16, max: 3600),
                RoundingTemplateRequiredLocaleRule(message: "rounding template needs this field"),
                RoundingTemplateRequiredPatientRefRule(message: "rounding template needs an entry"),
            ]
        )
    }
}
