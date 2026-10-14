import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol preference must pass. Check returns its problems, or none.
    protocol CareProtocolPreferenceRule {
        func check(_ item: CareProtocolPreference) -> [String]
    }

    final class CareProtocolPreferenceNameLengthRule: CareProtocolPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolPreferenceCurrencyLengthRule: CareProtocolPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolPreference) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolPreferenceAllowedCodeRule: CareProtocolPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class CareProtocolPreferenceRequiredCodeRule: CareProtocolPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolPreferenceRequiredTitleRule: CareProtocolPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol preference.
    final class CareProtocolPreferenceValidator {
        var rules: [any CareProtocolPreferenceRule]

        init(rules: [any CareProtocolPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolPreference) -> [String] {
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

        func requireValid(_ item: CareProtocolPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolPreference]) -> [String: [String]] {
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

    static func defaultCareProtocolPreferenceValidator() -> CareProtocolPreferenceValidator {
        return CareProtocolPreferenceValidator(
            rules: [
                CareProtocolPreferenceNameLengthRule(maxLength: 86400),
                CareProtocolPreferenceCurrencyLengthRule(maxLength: 3600),
                CareProtocolPreferenceAllowedCodeRule(allowed: []),
                CareProtocolPreferenceRequiredCodeRule(message: "care protocol preference needs a value"),
                CareProtocolPreferenceRequiredTitleRule(message: "care protocol preference needs a value"),
            ]
        )
    }
}
