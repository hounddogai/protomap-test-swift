import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a weighted rounding preference must pass. Check returns its problems, or none.
    protocol WeightedRoundingPreferenceRule {
        func check(_ item: WeightedRoundingPreference) -> [String]
    }

    final class WeightedRoundingPreferenceAttemptsRangeRule: WeightedRoundingPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedRoundingPreference) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedRoundingPreferenceRegionLengthRule: WeightedRoundingPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRoundingPreference) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRoundingPreferenceRequiredLabelRule: WeightedRoundingPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRoundingPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRoundingPreferenceProcedureCodeLengthRule: WeightedRoundingPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRoundingPreference) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRoundingPreferenceLabelLengthRule: WeightedRoundingPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRoundingPreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedRoundingPreferenceRequiredCodeRule: WeightedRoundingPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRoundingPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted rounding preference.
    final class WeightedRoundingPreferenceValidator {
        var rules: [any WeightedRoundingPreferenceRule]

        init(rules: [any WeightedRoundingPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRoundingPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedRoundingPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRoundingPreference]) -> [String: [String]] {
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

    static func defaultWeightedRoundingPreferenceValidator() -> WeightedRoundingPreferenceValidator {
        return WeightedRoundingPreferenceValidator(
            rules: [
                WeightedRoundingPreferenceAttemptsRangeRule(min: 32, max: 86400),
                WeightedRoundingPreferenceRegionLengthRule(maxLength: 120),
                WeightedRoundingPreferenceRequiredLabelRule(message: "weighted rounding preference needs this field"),
                WeightedRoundingPreferenceProcedureCodeLengthRule(maxLength: 80),
                WeightedRoundingPreferenceLabelLengthRule(maxLength: 120),
                WeightedRoundingPreferenceRequiredCodeRule(message: "weighted rounding preference needs an entry"),
            ]
        )
    }
}
