import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network schedule must pass. Check returns its problems, or none.
    protocol NetworkScheduleRule {
        func check(_ item: NetworkSchedule) -> [String]
    }

    final class NetworkScheduleTitleLengthRule: NetworkScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkSchedule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkScheduleAcuityRangeRule: NetworkScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkSchedule) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkScheduleRequiredTitleRule: NetworkScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkSchedule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkScheduleTimezoneLengthRule: NetworkScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkSchedule) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network schedule.
    final class NetworkScheduleValidator {
        var rules: [any NetworkScheduleRule]

        init(rules: [any NetworkScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkSchedule) -> [String] {
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

        func requireValid(_ item: NetworkSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkSchedule]) -> [String: [String]] {
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

    static func defaultNetworkScheduleValidator() -> NetworkScheduleValidator {
        return NetworkScheduleValidator(
            rules: [
                NetworkScheduleTitleLengthRule(maxLength: 3600),
                NetworkScheduleAcuityRangeRule(min: 120, max: 120),
                NetworkScheduleRequiredTitleRule(message: "network schedule needs this field"),
                NetworkScheduleTimezoneLengthRule(maxLength: 86400),
            ]
        )
    }
}
