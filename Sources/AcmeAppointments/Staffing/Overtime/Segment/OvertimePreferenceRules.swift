import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime preference must pass. Check returns its problems, or none.
    protocol OvertimePreferenceRule {
        func check(_ item: OvertimePreference) -> [String]
    }

    final class OvertimePreferenceCostRangeRule: OvertimePreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimePreference) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OvertimePreferenceCodeLengthRule: OvertimePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimePreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimePreferenceGraceDaysRangeRule: OvertimePreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimePreference) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OvertimePreferenceAllergyLengthRule: OvertimePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimePreference) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimePreferenceRequiredAllergyRule: OvertimePreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimePreference) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime preference.
    final class OvertimePreferenceValidator {
        var rules: [any OvertimePreferenceRule]

        init(rules: [any OvertimePreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimePreference) -> [String] {
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

        func requireValid(_ item: OvertimePreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimePreference]) -> [String: [String]] {
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

    static func defaultOvertimePreferenceValidator() -> OvertimePreferenceValidator {
        return OvertimePreferenceValidator(
            rules: [
                OvertimePreferenceCostRangeRule(min: 9.5, max: 2209.8),
                OvertimePreferenceCodeLengthRule(maxLength: 120),
                OvertimePreferenceGraceDaysRangeRule(min: 32, max: 32),
                OvertimePreferenceAllergyLengthRule(maxLength: 64),
                OvertimePreferenceRequiredAllergyRule(message: "overtime preference needs an entry"),
            ]
        )
    }
}
