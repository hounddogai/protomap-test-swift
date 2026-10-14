import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped inventory preference must pass. Check returns its problems, or none.
    protocol CappedInventoryPreferenceRule {
        func check(_ item: CappedInventoryPreference) -> [String]
    }

    final class CappedInventoryPreferenceRequiredNameRule: CappedInventoryPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedInventoryPreference) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedInventoryPreferenceNameLengthRule: CappedInventoryPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedInventoryPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedInventoryPreferenceRequiredClinicianIDRule: CappedInventoryPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedInventoryPreference) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedInventoryPreferenceRequiredCodeRule: CappedInventoryPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedInventoryPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped inventory preference.
    final class CappedInventoryPreferenceValidator {
        var rules: [any CappedInventoryPreferenceRule]

        init(rules: [any CappedInventoryPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedInventoryPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedInventoryPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedInventoryPreference]) -> [String: [String]] {
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

    static func defaultCappedInventoryPreferenceValidator() -> CappedInventoryPreferenceValidator {
        return CappedInventoryPreferenceValidator(
            rules: [
                CappedInventoryPreferenceRequiredNameRule(message: "capped inventory preference needs an entry"),
                CappedInventoryPreferenceNameLengthRule(maxLength: 120),
                CappedInventoryPreferenceRequiredClinicianIDRule(
                    message: "capped inventory preference needs this field"
                ),
                CappedInventoryPreferenceRequiredCodeRule(message: "capped inventory preference needs a value"),
            ]
        )
    }
}
