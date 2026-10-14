import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped consent form preference must pass. Check returns its problems, or none.
    protocol CappedConsentFormPreferenceRule {
        func check(_ item: CappedConsentFormPreference) -> [String]
    }

    final class CappedConsentFormPreferenceCodeLengthRule: CappedConsentFormPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedConsentFormPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedConsentFormPreferenceQuantityRangeRule: CappedConsentFormPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedConsentFormPreference) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedConsentFormPreferenceNameLengthRule: CappedConsentFormPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedConsentFormPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedConsentFormPreferenceRequiredNameRule: CappedConsentFormPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedConsentFormPreference) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedConsentFormPreferenceDiagnosisCodeLengthRule: CappedConsentFormPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedConsentFormPreference) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedConsentFormPreferenceCodePrefixRule: CappedConsentFormPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedConsentFormPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped consent form preference.
    final class CappedConsentFormPreferenceValidator {
        var rules: [any CappedConsentFormPreferenceRule]

        init(rules: [any CappedConsentFormPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedConsentFormPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedConsentFormPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedConsentFormPreference]) -> [String: [String]] {
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

    static func defaultCappedConsentFormPreferenceValidator() -> CappedConsentFormPreferenceValidator {
        return CappedConsentFormPreferenceValidator(
            rules: [
                CappedConsentFormPreferenceCodeLengthRule(maxLength: 86400),
                CappedConsentFormPreferenceQuantityRangeRule(min: 16, max: 86400),
                CappedConsentFormPreferenceNameLengthRule(maxLength: 120),
                CappedConsentFormPreferenceRequiredNameRule(
                    message: "capped consent form preference needs this field"
                ),
                CappedConsentFormPreferenceDiagnosisCodeLengthRule(maxLength: 3600),
                CappedConsentFormPreferenceCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
