import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness schedule must pass. Check returns its problems, or none.
    protocol WitnessScheduleRule {
        func check(_ item: WitnessSchedule) -> [String]
    }

    final class WitnessScheduleUpdatedAtRangeRule: WitnessScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessSchedule) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessScheduleRefillsRangeRule: WitnessScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessSchedule) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessScheduleRequiredBedRule: WitnessScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessSchedule) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness schedule.
    final class WitnessScheduleValidator {
        var rules: [any WitnessScheduleRule]

        init(rules: [any WitnessScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessSchedule]) -> [String: [String]] {
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

    static func defaultWitnessScheduleValidator() -> WitnessScheduleValidator {
        return WitnessScheduleValidator(
            rules: [
                WitnessScheduleUpdatedAtRangeRule(min: 32, max: 64),
                WitnessScheduleRefillsRangeRule(min: 32, max: 80),
                WitnessScheduleRequiredBedRule(message: "witness schedule needs an entry"),
            ]
        )
    }
}
