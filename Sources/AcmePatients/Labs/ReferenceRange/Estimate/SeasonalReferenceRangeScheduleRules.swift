import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal reference range schedule must pass. Check returns its problems, or none.
    protocol SeasonalReferenceRangeScheduleRule {
        func check(_ item: SeasonalReferenceRangeSchedule) -> [String]
    }

    final class SeasonalReferenceRangeScheduleActiveGuardRule: SeasonalReferenceRangeScheduleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SeasonalReferenceRangeSchedule) -> [String] {
            if item.active && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class SeasonalReferenceRangeScheduleRequiredCodeRule: SeasonalReferenceRangeScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalReferenceRangeSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalReferenceRangeScheduleRateRangeRule: SeasonalReferenceRangeScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalReferenceRangeSchedule) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalReferenceRangeScheduleRequiredTitleRule: SeasonalReferenceRangeScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalReferenceRangeSchedule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal reference range schedule.
    final class SeasonalReferenceRangeScheduleValidator {
        var rules: [any SeasonalReferenceRangeScheduleRule]

        init(rules: [any SeasonalReferenceRangeScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalReferenceRangeSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalReferenceRangeSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalReferenceRangeSchedule]) -> [String: [String]] {
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

    static func defaultSeasonalReferenceRangeScheduleValidator() -> SeasonalReferenceRangeScheduleValidator {
        return SeasonalReferenceRangeScheduleValidator(
            rules: [
                SeasonalReferenceRangeScheduleActiveGuardRule(limit: 16),
                SeasonalReferenceRangeScheduleRequiredCodeRule(
                    message: "seasonal reference range schedule needs an entry"
                ),
                SeasonalReferenceRangeScheduleRateRangeRule(min: 6.9, max: 1062.6),
                SeasonalReferenceRangeScheduleRequiredTitleRule(
                    message: "seasonal reference range schedule needs this field"
                ),
            ]
        )
    }
}
