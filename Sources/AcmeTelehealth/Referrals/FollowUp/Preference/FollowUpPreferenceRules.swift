import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up preference must pass. Check returns its problems, or none.
    protocol FollowUpPreferenceRule {
        func check(_ item: FollowUpPreference) -> [String]
    }

    final class FollowUpPreferenceCodeLengthRule: FollowUpPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpPreferenceCodePrefixRule: FollowUpPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpPreferenceNameLengthRule: FollowUpPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpPreferenceProcedureCodeLengthRule: FollowUpPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpPreference) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpPreferenceAllergyLengthRule: FollowUpPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpPreference) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up preference.
    final class FollowUpPreferenceValidator {
        var rules: [any FollowUpPreferenceRule]

        init(rules: [any FollowUpPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpPreference]) -> [String: [String]] {
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

    static func defaultFollowUpPreferenceValidator() -> FollowUpPreferenceValidator {
        return FollowUpPreferenceValidator(
            rules: [
                FollowUpPreferenceCodeLengthRule(maxLength: 86400),
                FollowUpPreferenceCodePrefixRule(prefix: "ACM"),
                FollowUpPreferenceNameLengthRule(maxLength: 64),
                FollowUpPreferenceProcedureCodeLengthRule(maxLength: 255),
                FollowUpPreferenceAllergyLengthRule(maxLength: 32),
            ]
        )
    }
}
