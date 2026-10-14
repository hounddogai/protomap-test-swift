import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach preference must pass. Check returns its problems, or none.
    protocol OutreachPreferenceRule {
        func check(_ item: OutreachPreference) -> [String]
    }

    final class OutreachPreferenceLimitRangeRule: OutreachPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachPreference) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachPreferenceCategoryLengthRule: OutreachPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachPreference) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachPreferenceAllowedCategoryRule: OutreachPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OutreachPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is duplicated"]
            }
            return []
        }
    }

    final class OutreachPreferenceRequiredCodeRule: OutreachPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a outreach preference.
    final class OutreachPreferenceValidator {
        var rules: [any OutreachPreferenceRule]

        init(rules: [any OutreachPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachPreference]) -> [String: [String]] {
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

    static func defaultOutreachPreferenceValidator() -> OutreachPreferenceValidator {
        return OutreachPreferenceValidator(
            rules: [
                OutreachPreferenceLimitRangeRule(min: 1000, max: 86400),
                OutreachPreferenceCategoryLengthRule(maxLength: 1000),
                OutreachPreferenceAllowedCategoryRule(allowed: ["legacy", "lenient"]),
                OutreachPreferenceRequiredCodeRule(message: "outreach preference needs an entry"),
            ]
        )
    }
}
