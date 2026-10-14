import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional skill mix profile must pass. Check returns its problems, or none.
    protocol RegionalSkillMixProfileRule {
        func check(_ item: RegionalSkillMixProfile) -> [String]
    }

    final class RegionalSkillMixProfileRequiredExternalRefRule: RegionalSkillMixProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSkillMixProfile) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalSkillMixProfileProcedureCodeLengthRule: RegionalSkillMixProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSkillMixProfile) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalSkillMixProfileAllowedCodeRule: RegionalSkillMixProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalSkillMixProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class RegionalSkillMixProfileExternalRefLengthRule: RegionalSkillMixProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSkillMixProfile) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional skill mix profile.
    final class RegionalSkillMixProfileValidator {
        var rules: [any RegionalSkillMixProfileRule]

        init(rules: [any RegionalSkillMixProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSkillMixProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalSkillMixProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSkillMixProfile]) -> [String: [String]] {
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

    static func defaultRegionalSkillMixProfileValidator() -> RegionalSkillMixProfileValidator {
        return RegionalSkillMixProfileValidator(
            rules: [
                RegionalSkillMixProfileRequiredExternalRefRule(message: "regional skill mix profile needs this field"),
                RegionalSkillMixProfileProcedureCodeLengthRule(maxLength: 16),
                RegionalSkillMixProfileAllowedCodeRule(allowed: []),
                RegionalSkillMixProfileExternalRefLengthRule(maxLength: 86400),
            ]
        )
    }
}
