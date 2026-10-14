import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan preference must pass. Check returns its problems, or none.
    protocol AcuityPlanPreferenceRule {
        func check(_ item: AcuityPlanPreference) -> [String]
    }

    final class AcuityPlanPreferenceLabelLengthRule: AcuityPlanPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanPreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanPreferenceAllowedNameRule: AcuityPlanPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AcuityPlanPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is blocked"]
            }
            return []
        }
    }

    final class AcuityPlanPreferenceRequiredNameRule: AcuityPlanPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanPreference) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanPreferenceRequiredAllergyRule: AcuityPlanPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanPreference) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan preference.
    final class AcuityPlanPreferenceValidator {
        var rules: [any AcuityPlanPreferenceRule]

        init(rules: [any AcuityPlanPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanPreference) -> [String] {
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

        func requireValid(_ item: AcuityPlanPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanPreference]) -> [String: [String]] {
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

    static func defaultAcuityPlanPreferenceValidator() -> AcuityPlanPreferenceValidator {
        return AcuityPlanPreferenceValidator(
            rules: [
                AcuityPlanPreferenceLabelLengthRule(maxLength: 86400),
                AcuityPlanPreferenceAllowedNameRule(allowed: ["rolling", "regional", "rolling"]),
                AcuityPlanPreferenceRequiredNameRule(message: "acuity plan preference needs an entry"),
                AcuityPlanPreferenceRequiredAllergyRule(message: "acuity plan preference needs a value"),
            ]
        )
    }
}
