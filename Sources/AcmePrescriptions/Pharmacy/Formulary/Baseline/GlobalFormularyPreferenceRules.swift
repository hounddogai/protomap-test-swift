import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global formulary preference must pass. Check returns its problems, or none.
    protocol GlobalFormularyPreferenceRule {
        func check(_ item: GlobalFormularyPreference) -> [String]
    }

    final class GlobalFormularyPreferenceAttemptsRangeRule: GlobalFormularyPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalFormularyPreference) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalFormularyPreferenceRefillsRangeRule: GlobalFormularyPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalFormularyPreference) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalFormularyPreferenceRequiredCategoryRule: GlobalFormularyPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalFormularyPreference) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global formulary preference.
    final class GlobalFormularyPreferenceValidator {
        var rules: [any GlobalFormularyPreferenceRule]

        init(rules: [any GlobalFormularyPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalFormularyPreference) -> [String] {
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

        func requireValid(_ item: GlobalFormularyPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalFormularyPreference]) -> [String: [String]] {
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

    static func defaultGlobalFormularyPreferenceValidator() -> GlobalFormularyPreferenceValidator {
        return GlobalFormularyPreferenceValidator(
            rules: [
                GlobalFormularyPreferenceAttemptsRangeRule(min: 64, max: 86400),
                GlobalFormularyPreferenceRefillsRangeRule(min: 120, max: 86400),
                GlobalFormularyPreferenceRequiredCategoryRule(message: "global formulary preference needs an entry"),
            ]
        )
    }
}
