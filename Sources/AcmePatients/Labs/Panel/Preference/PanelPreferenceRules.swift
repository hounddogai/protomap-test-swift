import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel preference must pass. Check returns its problems, or none.
    protocol PanelPreferenceRule {
        func check(_ item: PanelPreference) -> [String]
    }

    final class PanelPreferenceRequiredCurrencyRule: PanelPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelPreference) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelPreferenceCodePrefixRule: PanelPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PanelPreferenceRequiredCodeRule: PanelPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelPreferenceDiagnosisCodeLengthRule: PanelPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelPreference) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelPreferenceCurrencyLengthRule: PanelPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelPreference) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel preference.
    final class PanelPreferenceValidator {
        var rules: [any PanelPreferenceRule]

        init(rules: [any PanelPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelPreference) -> [String] {
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

        func requireValid(_ item: PanelPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelPreference]) -> [String: [String]] {
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

    static func defaultPanelPreferenceValidator() -> PanelPreferenceValidator {
        return PanelPreferenceValidator(
            rules: [
                PanelPreferenceRequiredCurrencyRule(message: "panel preference needs an entry"),
                PanelPreferenceCodePrefixRule(prefix: "REF"),
                PanelPreferenceRequiredCodeRule(message: "panel preference needs an entry"),
                PanelPreferenceDiagnosisCodeLengthRule(maxLength: 3600),
                PanelPreferenceCurrencyLengthRule(maxLength: 3600),
            ]
        )
    }
}
