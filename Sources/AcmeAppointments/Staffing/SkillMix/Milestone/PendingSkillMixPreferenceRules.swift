import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending skill mix preference must pass. Check returns its problems, or none.
    protocol PendingSkillMixPreferenceRule {
        func check(_ item: PendingSkillMixPreference) -> [String]
    }

    final class PendingSkillMixPreferenceAllowedFacilityRule: PendingSkillMixPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingSkillMixPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is blocked"]
            }
            return []
        }
    }

    final class PendingSkillMixPreferenceRequiredFacilityRule: PendingSkillMixPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSkillMixPreference) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSkillMixPreferenceTitleLengthRule: PendingSkillMixPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingSkillMixPreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingSkillMixPreferenceFacilityLengthRule: PendingSkillMixPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingSkillMixPreference) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending skill mix preference.
    final class PendingSkillMixPreferenceValidator {
        var rules: [any PendingSkillMixPreferenceRule]

        init(rules: [any PendingSkillMixPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingSkillMixPreference) -> [String] {
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

        func requireValid(_ item: PendingSkillMixPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingSkillMixPreference]) -> [String: [String]] {
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

    static func defaultPendingSkillMixPreferenceValidator() -> PendingSkillMixPreferenceValidator {
        return PendingSkillMixPreferenceValidator(
            rules: [
                PendingSkillMixPreferenceAllowedFacilityRule(allowed: ["capped", "lenient", "weighted"]),
                PendingSkillMixPreferenceRequiredFacilityRule(
                    message: "pending skill mix preference needs this field"
                ),
                PendingSkillMixPreferenceTitleLengthRule(maxLength: 1000),
                PendingSkillMixPreferenceFacilityLengthRule(maxLength: 86400),
            ]
        )
    }
}
