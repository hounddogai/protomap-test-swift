import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility preference must pass. Check returns its problems, or none.
    protocol EligibilityPreferenceRule {
        func check(_ item: EligibilityPreference) -> [String]
    }

    final class EligibilityPreferenceCodeLengthRule: EligibilityPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityPreferenceRequiredCodeRule: EligibilityPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityPreferenceMinimumRangeRule: EligibilityPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityPreference) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class EligibilityPreferenceRequiredPatientRefRule: EligibilityPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityPreference) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityPreferenceTagsLimitRule: EligibilityPreferenceRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: EligibilityPreference) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class EligibilityPreferenceNameLengthRule: EligibilityPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityPreference) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility preference.
    final class EligibilityPreferenceValidator {
        var rules: [any EligibilityPreferenceRule]

        init(rules: [any EligibilityPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityPreference) -> [String] {
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

        func requireValid(_ item: EligibilityPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityPreference]) -> [String: [String]] {
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

    static func defaultEligibilityPreferenceValidator() -> EligibilityPreferenceValidator {
        return EligibilityPreferenceValidator(
            rules: [
                EligibilityPreferenceCodeLengthRule(maxLength: 3600),
                EligibilityPreferenceRequiredCodeRule(message: "eligibility preference needs an entry"),
                EligibilityPreferenceMinimumRangeRule(min: 1.0, max: 1704.3),
                EligibilityPreferenceRequiredPatientRefRule(message: "eligibility preference needs a value"),
                EligibilityPreferenceTagsLimitRule(maxCount: 16, banned: ["tiered", "rolling"]),
                EligibilityPreferenceNameLengthRule(maxLength: 32),
            ]
        )
    }
}
