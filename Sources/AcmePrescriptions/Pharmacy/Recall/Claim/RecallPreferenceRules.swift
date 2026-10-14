import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall preference must pass. Check returns its problems, or none.
    protocol RecallPreferenceRule {
        func check(_ item: RecallPreference) -> [String]
    }

    final class RecallPreferenceLimitRangeRule: RecallPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallPreference) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallPreferenceUpdatedAtRangeRule: RecallPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallPreference) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RecallPreferenceBudgetRangeRule: RecallPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallPreference) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallPreferenceRequiredCodeRule: RecallPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallPreferenceRequiredLabelRule: RecallPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall preference.
    final class RecallPreferenceValidator {
        var rules: [any RecallPreferenceRule]

        init(rules: [any RecallPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallPreference) -> [String] {
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

        func requireValid(_ item: RecallPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallPreference]) -> [String: [String]] {
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

    static func defaultRecallPreferenceValidator() -> RecallPreferenceValidator {
        return RecallPreferenceValidator(
            rules: [
                RecallPreferenceLimitRangeRule(min: 80, max: 255),
                RecallPreferenceUpdatedAtRangeRule(min: 64, max: 120),
                RecallPreferenceBudgetRangeRule(min: 0.7, max: 278.7),
                RecallPreferenceRequiredCodeRule(message: "recall preference needs a value"),
                RecallPreferenceRequiredLabelRule(message: "recall preference needs a value"),
            ]
        )
    }
}
