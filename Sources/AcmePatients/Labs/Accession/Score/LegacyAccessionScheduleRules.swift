import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy accession schedule must pass. Check returns its problems, or none.
    protocol LegacyAccessionScheduleRule {
        func check(_ item: LegacyAccessionSchedule) -> [String]
    }

    final class LegacyAccessionScheduleRefillsRangeRule: LegacyAccessionScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAccessionSchedule) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyAccessionScheduleAttemptsRangeRule: LegacyAccessionScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAccessionSchedule) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyAccessionScheduleRequiredAllergyRule: LegacyAccessionScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAccessionSchedule) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy accession schedule.
    final class LegacyAccessionScheduleValidator {
        var rules: [any LegacyAccessionScheduleRule]

        init(rules: [any LegacyAccessionScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAccessionSchedule) -> [String] {
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

        func requireValid(_ item: LegacyAccessionSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAccessionSchedule]) -> [String: [String]] {
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

    static func defaultLegacyAccessionScheduleValidator() -> LegacyAccessionScheduleValidator {
        return LegacyAccessionScheduleValidator(
            rules: [
                LegacyAccessionScheduleRefillsRangeRule(min: 1000, max: 86400),
                LegacyAccessionScheduleAttemptsRangeRule(min: 32, max: 1000),
                LegacyAccessionScheduleRequiredAllergyRule(message: "legacy accession schedule needs an entry"),
            ]
        )
    }
}
