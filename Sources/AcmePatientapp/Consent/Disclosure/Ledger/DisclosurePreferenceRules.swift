import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure preference must pass. Check returns its problems, or none.
    protocol DisclosurePreferenceRule {
        func check(_ item: DisclosurePreference) -> [String]
    }

    final class DisclosurePreferenceProcedureCodeLengthRule: DisclosurePreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosurePreference) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosurePreferenceAllowedProcedureCodeRule: DisclosurePreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DisclosurePreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is missing"]
            }
            return []
        }
    }

    final class DisclosurePreferenceRequiredCodeRule: DisclosurePreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosurePreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosurePreferenceCodePrefixRule: DisclosurePreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosurePreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DisclosurePreferenceAmountRangeRule: DisclosurePreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosurePreference) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a disclosure preference.
    final class DisclosurePreferenceValidator {
        var rules: [any DisclosurePreferenceRule]

        init(rules: [any DisclosurePreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosurePreference) -> [String] {
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

        func requireValid(_ item: DisclosurePreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosurePreference]) -> [String: [String]] {
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

    static func defaultDisclosurePreferenceValidator() -> DisclosurePreferenceValidator {
        return DisclosurePreferenceValidator(
            rules: [
                DisclosurePreferenceProcedureCodeLengthRule(maxLength: 16),
                DisclosurePreferenceAllowedProcedureCodeRule(allowed: ["weighted"]),
                DisclosurePreferenceRequiredCodeRule(message: "disclosure preference needs a value"),
                DisclosurePreferenceCodePrefixRule(prefix: "REF"),
                DisclosurePreferenceAmountRangeRule(min: 0.1, max: 442.4),
            ]
        )
    }
}
