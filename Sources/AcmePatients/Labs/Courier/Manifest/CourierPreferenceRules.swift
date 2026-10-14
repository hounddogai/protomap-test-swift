import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier preference must pass. Check returns its problems, or none.
    protocol CourierPreferenceRule {
        func check(_ item: CourierPreference) -> [String]
    }

    final class CourierPreferencePhoneLengthRule: CourierPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierPreference) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierPreferenceCodePrefixRule: CourierPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CourierPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CourierPreferenceRequiredTitleRule: CourierPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierPreferenceCodeLengthRule: CourierPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierPreferenceRequiredPhoneRule: CourierPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierPreference) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierPreferenceRequiredCodeRule: CourierPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a courier preference.
    final class CourierPreferenceValidator {
        var rules: [any CourierPreferenceRule]

        init(rules: [any CourierPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierPreference) -> [String] {
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

        func requireValid(_ item: CourierPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierPreference]) -> [String: [String]] {
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

    static func defaultCourierPreferenceValidator() -> CourierPreferenceValidator {
        return CourierPreferenceValidator(
            rules: [
                CourierPreferencePhoneLengthRule(maxLength: 86400),
                CourierPreferenceCodePrefixRule(prefix: "X"),
                CourierPreferenceRequiredTitleRule(message: "courier preference needs a value"),
                CourierPreferenceCodeLengthRule(maxLength: 80),
                CourierPreferenceRequiredPhoneRule(message: "courier preference needs an entry"),
                CourierPreferenceRequiredCodeRule(message: "courier preference needs a value"),
            ]
        )
    }
}
