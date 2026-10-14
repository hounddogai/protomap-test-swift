import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up forecast must pass. Check returns its problems, or none.
    protocol FollowUpForecastRule {
        func check(_ item: FollowUpForecast) -> [String]
    }

    final class FollowUpForecastRequiredOwnerIDRule: FollowUpForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpForecast) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpForecastVisitMinutesRangeRule: FollowUpForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpForecast) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpForecastRequiredNotesRule: FollowUpForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpForecast) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpForecastAmountRangeRule: FollowUpForecastRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpForecast) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FollowUpForecastRequiredTitleRule: FollowUpForecastRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpForecast) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpForecastCapacityRangeRule: FollowUpForecastRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpForecast) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up forecast.
    final class FollowUpForecastValidator {
        var rules: [any FollowUpForecastRule]

        init(rules: [any FollowUpForecastRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpForecast) -> [String] {
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

        func requireValid(_ item: FollowUpForecast) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpForecast]) -> [String: [String]] {
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

    static func defaultFollowUpForecastValidator() -> FollowUpForecastValidator {
        return FollowUpForecastValidator(
            rules: [
                FollowUpForecastRequiredOwnerIDRule(message: "follow up forecast needs a value"),
                FollowUpForecastVisitMinutesRangeRule(min: 80, max: 86400),
                FollowUpForecastRequiredNotesRule(message: "follow up forecast needs this field"),
                FollowUpForecastAmountRangeRule(min: 5.4, max: 4067.8),
                FollowUpForecastRequiredTitleRule(message: "follow up forecast needs an entry"),
                FollowUpForecastCapacityRangeRule(min: 32, max: 120),
            ]
        )
    }
}
