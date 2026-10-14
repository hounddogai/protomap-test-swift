import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback eligibility template must pass. Check returns its problems, or none.
    protocol FallbackEligibilityTemplateRule {
        func check(_ item: FallbackEligibilityTemplate) -> [String]
    }

    final class FallbackEligibilityTemplateRequiredCodeRule: FallbackEligibilityTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackEligibilityTemplateClinicianIDLengthRule: FallbackEligibilityTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackEligibilityTemplate) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackEligibilityTemplateRequiredLabelRule: FallbackEligibilityTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackEligibilityTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackEligibilityTemplateDosageMgRangeRule: FallbackEligibilityTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackEligibilityTemplate) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback eligibility template.
    final class FallbackEligibilityTemplateValidator {
        var rules: [any FallbackEligibilityTemplateRule]

        init(rules: [any FallbackEligibilityTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackEligibilityTemplate) -> [String] {
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

        func requireValid(_ item: FallbackEligibilityTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackEligibilityTemplate]) -> [String: [String]] {
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

    static func defaultFallbackEligibilityTemplateValidator() -> FallbackEligibilityTemplateValidator {
        return FallbackEligibilityTemplateValidator(
            rules: [
                FallbackEligibilityTemplateRequiredCodeRule(message: "fallback eligibility template needs a value"),
                FallbackEligibilityTemplateClinicianIDLengthRule(maxLength: 32),
                FallbackEligibilityTemplateRequiredLabelRule(message: "fallback eligibility template needs an entry"),
                FallbackEligibilityTemplateDosageMgRangeRule(min: 8.9, max: 4552.4),
            ]
        )
    }
}
