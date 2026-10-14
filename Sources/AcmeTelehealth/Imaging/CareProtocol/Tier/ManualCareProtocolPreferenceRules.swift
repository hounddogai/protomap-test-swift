import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a manual care protocol preference must pass. Check returns its problems, or none.
    protocol ManualCareProtocolPreferenceRule {
        func check(_ item: ManualCareProtocolPreference) -> [String]
    }

    final class ManualCareProtocolPreferenceRequiredLabelRule: ManualCareProtocolPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCareProtocolPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCareProtocolPreferenceNameLengthRule: ManualCareProtocolPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareProtocolPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareProtocolPreferenceOwnerIDLengthRule: ManualCareProtocolPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareProtocolPreference) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCareProtocolPreferenceRequiredCodeRule: ManualCareProtocolPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCareProtocolPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual care protocol preference.
    final class ManualCareProtocolPreferenceValidator {
        var rules: [any ManualCareProtocolPreferenceRule]

        init(rules: [any ManualCareProtocolPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCareProtocolPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualCareProtocolPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCareProtocolPreference]) -> [String: [String]] {
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

    static func defaultManualCareProtocolPreferenceValidator() -> ManualCareProtocolPreferenceValidator {
        return ManualCareProtocolPreferenceValidator(
            rules: [
                ManualCareProtocolPreferenceRequiredLabelRule(
                    message: "manual care protocol preference needs a value"
                ),
                ManualCareProtocolPreferenceNameLengthRule(maxLength: 80),
                ManualCareProtocolPreferenceOwnerIDLengthRule(maxLength: 3600),
                ManualCareProtocolPreferenceRequiredCodeRule(
                    message: "manual care protocol preference needs this field"
                ),
            ]
        )
    }
}
