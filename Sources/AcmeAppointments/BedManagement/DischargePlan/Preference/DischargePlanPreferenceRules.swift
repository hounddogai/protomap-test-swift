import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan preference must pass. Check returns its problems, or none.
    protocol DischargePlanPreferenceRule {
        func check(_ item: DischargePlanPreference) -> [String]
    }

    final class DischargePlanPreferenceRequiredNameRule: DischargePlanPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanPreference) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanPreferenceCodeLengthRule: DischargePlanPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanPreferenceDiscountRangeRule: DischargePlanPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanPreference) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanPreferenceTitleLengthRule: DischargePlanPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanPreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan preference.
    final class DischargePlanPreferenceValidator {
        var rules: [any DischargePlanPreferenceRule]

        init(rules: [any DischargePlanPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanPreference) -> [String] {
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

        func requireValid(_ item: DischargePlanPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanPreference]) -> [String: [String]] {
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

    static func defaultDischargePlanPreferenceValidator() -> DischargePlanPreferenceValidator {
        return DischargePlanPreferenceValidator(
            rules: [
                DischargePlanPreferenceRequiredNameRule(message: "discharge plan preference needs an entry"),
                DischargePlanPreferenceCodeLengthRule(maxLength: 3600),
                DischargePlanPreferenceDiscountRangeRule(min: 7.2, max: 1543.5),
                DischargePlanPreferenceTitleLengthRule(maxLength: 120),
            ]
        )
    }
}
