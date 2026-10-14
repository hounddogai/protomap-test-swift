import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient isolation preference must pass. Check returns its problems, or none.
    protocol LenientIsolationPreferenceRule {
        func check(_ item: LenientIsolationPreference) -> [String]
    }

    final class LenientIsolationPreferenceRequiredAllergyRule: LenientIsolationPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientIsolationPreference) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientIsolationPreferenceRequiredTitleRule: LenientIsolationPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientIsolationPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientIsolationPreferenceLimitRangeRule: LenientIsolationPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientIsolationPreference) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient isolation preference.
    final class LenientIsolationPreferenceValidator {
        var rules: [any LenientIsolationPreferenceRule]

        init(rules: [any LenientIsolationPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientIsolationPreference) -> [String] {
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

        func requireValid(_ item: LenientIsolationPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientIsolationPreference]) -> [String: [String]] {
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

    static func defaultLenientIsolationPreferenceValidator() -> LenientIsolationPreferenceValidator {
        return LenientIsolationPreferenceValidator(
            rules: [
                LenientIsolationPreferenceRequiredAllergyRule(message: "lenient isolation preference needs a value"),
                LenientIsolationPreferenceRequiredTitleRule(message: "lenient isolation preference needs this field"),
                LenientIsolationPreferenceLimitRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
