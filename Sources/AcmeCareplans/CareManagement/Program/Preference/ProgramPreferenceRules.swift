import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program preference must pass. Check returns its problems, or none.
    protocol ProgramPreferenceRule {
        func check(_ item: ProgramPreference) -> [String]
    }

    final class ProgramPreferenceDurationMinutesRangeRule: ProgramPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramPreference) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProgramPreferenceTagsLimitRule: ProgramPreferenceRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ProgramPreference) -> [String] {
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

    final class ProgramPreferenceRequiredCodeRule: ProgramPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a program preference.
    final class ProgramPreferenceValidator {
        var rules: [any ProgramPreferenceRule]

        init(rules: [any ProgramPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramPreference]) -> [String: [String]] {
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

    static func defaultProgramPreferenceValidator() -> ProgramPreferenceValidator {
        return ProgramPreferenceValidator(
            rules: [
                ProgramPreferenceDurationMinutesRangeRule(min: 64, max: 255),
                ProgramPreferenceTagsLimitRule(maxCount: 16, banned: []),
                ProgramPreferenceRequiredCodeRule(message: "program preference needs this field"),
            ]
        )
    }
}
