import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read schedule must pass. Check returns its problems, or none.
    protocol ReadScheduleRule {
        func check(_ item: ReadSchedule) -> [String]
    }

    final class ReadScheduleNameLengthRule: ReadScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadScheduleExpiresAtRangeRule: ReadScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadSchedule) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReadScheduleFacilityLengthRule: ReadScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadSchedule) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadScheduleCeilingRangeRule: ReadScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadSchedule) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReadScheduleCopayRangeRule: ReadScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadSchedule) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReadScheduleDiscountRangeRule: ReadScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadSchedule) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a read schedule.
    final class ReadScheduleValidator {
        var rules: [any ReadScheduleRule]

        init(rules: [any ReadScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadSchedule]) -> [String: [String]] {
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

    static func defaultReadScheduleValidator() -> ReadScheduleValidator {
        return ReadScheduleValidator(
            rules: [
                ReadScheduleNameLengthRule(maxLength: 86400),
                ReadScheduleExpiresAtRangeRule(min: 255, max: 3600),
                ReadScheduleFacilityLengthRule(maxLength: 80),
                ReadScheduleCeilingRangeRule(min: 7.1, max: 4786.5),
                ReadScheduleCopayRangeRule(min: 7.6, max: 4900.7),
                ReadScheduleDiscountRangeRule(min: 0.9, max: 1446.1),
            ]
        )
    }
}
