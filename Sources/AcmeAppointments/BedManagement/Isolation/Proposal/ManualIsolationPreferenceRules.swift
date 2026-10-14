import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual isolation preference must pass. Check returns its problems, or none.
    protocol ManualIsolationPreferenceRule {
        func check(_ item: ManualIsolationPreference) -> [String]
    }

    final class ManualIsolationPreferenceRequiredCurrencyRule: ManualIsolationPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualIsolationPreference) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualIsolationPreferenceCodeLengthRule: ManualIsolationPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualIsolationPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualIsolationPreferenceScoreRangeRule: ManualIsolationPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualIsolationPreference) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualIsolationPreferenceNameLengthRule: ManualIsolationPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualIsolationPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualIsolationPreferenceNotesLengthRule: ManualIsolationPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualIsolationPreference) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual isolation preference.
    final class ManualIsolationPreferenceValidator {
        var rules: [any ManualIsolationPreferenceRule]

        init(rules: [any ManualIsolationPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualIsolationPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualIsolationPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualIsolationPreference]) -> [String: [String]] {
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

    static func defaultManualIsolationPreferenceValidator() -> ManualIsolationPreferenceValidator {
        return ManualIsolationPreferenceValidator(
            rules: [
                ManualIsolationPreferenceRequiredCurrencyRule(message: "manual isolation preference needs an entry"),
                ManualIsolationPreferenceCodeLengthRule(maxLength: 32),
                ManualIsolationPreferenceScoreRangeRule(min: 8.4, max: 946.0),
                ManualIsolationPreferenceNameLengthRule(maxLength: 32),
                ManualIsolationPreferenceNotesLengthRule(maxLength: 86400),
            ]
        )
    }
}
