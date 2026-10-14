import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist preference must pass. Check returns its problems, or none.
    protocol WorklistPreferenceRule {
        func check(_ item: WorklistPreference) -> [String]
    }

    final class WorklistPreferenceRatioRangeRule: WorklistPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistPreference) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistPreferenceRequiredCodeRule: WorklistPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistPreferenceRequiredLabelRule: WorklistPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistPreferenceAllowedLabelRule: WorklistPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WorklistPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class WorklistPreferenceCodeLengthRule: WorklistPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist preference.
    final class WorklistPreferenceValidator {
        var rules: [any WorklistPreferenceRule]

        init(rules: [any WorklistPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistPreference]) -> [String: [String]] {
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

    static func defaultWorklistPreferenceValidator() -> WorklistPreferenceValidator {
        return WorklistPreferenceValidator(
            rules: [
                WorklistPreferenceRatioRangeRule(min: 2.8, max: 3527.0),
                WorklistPreferenceRequiredCodeRule(message: "worklist preference needs this field"),
                WorklistPreferenceRequiredLabelRule(message: "worklist preference needs a value"),
                WorklistPreferenceAllowedLabelRule(allowed: []),
                WorklistPreferenceCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
