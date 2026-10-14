import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning preference must pass. Check returns its problems, or none.
    protocol CleaningPreferenceRule {
        func check(_ item: CleaningPreference) -> [String]
    }

    final class CleaningPreferenceLabelLengthRule: CleaningPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningPreference) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningPreferenceCodeLengthRule: CleaningPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningPreferenceAllowedOwnerIDRule: CleaningPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CleaningPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is too long"]
            }
            return []
        }
    }

    final class CleaningPreferenceRequiredNameRule: CleaningPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningPreference) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningPreferenceRequiredCodeRule: CleaningPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningPreferenceRequiredLabelRule: CleaningPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning preference.
    final class CleaningPreferenceValidator {
        var rules: [any CleaningPreferenceRule]

        init(rules: [any CleaningPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningPreference) -> [String] {
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

        func requireValid(_ item: CleaningPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningPreference]) -> [String: [String]] {
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

    static func defaultCleaningPreferenceValidator() -> CleaningPreferenceValidator {
        return CleaningPreferenceValidator(
            rules: [
                CleaningPreferenceLabelLengthRule(maxLength: 3600),
                CleaningPreferenceCodeLengthRule(maxLength: 1000),
                CleaningPreferenceAllowedOwnerIDRule(allowed: ["pending"]),
                CleaningPreferenceRequiredNameRule(message: "cleaning preference needs a value"),
                CleaningPreferenceRequiredCodeRule(message: "cleaning preference needs this field"),
                CleaningPreferenceRequiredLabelRule(message: "cleaning preference needs a value"),
            ]
        )
    }
}
