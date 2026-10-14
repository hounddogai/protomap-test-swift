import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a regional census preference must pass. Check returns its problems, or none.
    protocol RegionalCensusPreferenceRule {
        func check(_ item: RegionalCensusPreference) -> [String]
    }

    final class RegionalCensusPreferenceRetriesRangeRule: RegionalCensusPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalCensusPreference) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalCensusPreferenceRequiredCodeRule: RegionalCensusPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCensusPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCensusPreferenceDurationMinutesRangeRule: RegionalCensusPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalCensusPreference) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalCensusPreferenceExpiresAtRangeRule: RegionalCensusPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalCensusPreference) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a regional census preference.
    final class RegionalCensusPreferenceValidator {
        var rules: [any RegionalCensusPreferenceRule]

        init(rules: [any RegionalCensusPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCensusPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalCensusPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCensusPreference]) -> [String: [String]] {
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

    static func defaultRegionalCensusPreferenceValidator() -> RegionalCensusPreferenceValidator {
        return RegionalCensusPreferenceValidator(
            rules: [
                RegionalCensusPreferenceRetriesRangeRule(min: 255, max: 3600),
                RegionalCensusPreferenceRequiredCodeRule(message: "regional census preference needs an entry"),
                RegionalCensusPreferenceDurationMinutesRangeRule(min: 32, max: 80),
                RegionalCensusPreferenceExpiresAtRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
