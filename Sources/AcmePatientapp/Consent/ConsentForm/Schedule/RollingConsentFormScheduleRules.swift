import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling consent form schedule must pass. Check returns its problems, or none.
    protocol RollingConsentFormScheduleRule {
        func check(_ item: RollingConsentFormSchedule) -> [String]
    }

    final class RollingConsentFormScheduleRequiredCountryRule: RollingConsentFormScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingConsentFormSchedule) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingConsentFormScheduleWardLengthRule: RollingConsentFormScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingConsentFormSchedule) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingConsentFormScheduleLabelLengthRule: RollingConsentFormScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingConsentFormSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingConsentFormScheduleRequiredWardRule: RollingConsentFormScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingConsentFormSchedule) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingConsentFormScheduleUpdatedAtRangeRule: RollingConsentFormScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingConsentFormSchedule) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingConsentFormScheduleCodeLengthRule: RollingConsentFormScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingConsentFormSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling consent form schedule.
    final class RollingConsentFormScheduleValidator {
        var rules: [any RollingConsentFormScheduleRule]

        init(rules: [any RollingConsentFormScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingConsentFormSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingConsentFormSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingConsentFormSchedule]) -> [String: [String]] {
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

    static func defaultRollingConsentFormScheduleValidator() -> RollingConsentFormScheduleValidator {
        return RollingConsentFormScheduleValidator(
            rules: [
                RollingConsentFormScheduleRequiredCountryRule(message: "rolling consent form schedule needs an entry"),
                RollingConsentFormScheduleWardLengthRule(maxLength: 3600),
                RollingConsentFormScheduleLabelLengthRule(maxLength: 255),
                RollingConsentFormScheduleRequiredWardRule(message: "rolling consent form schedule needs a value"),
                RollingConsentFormScheduleUpdatedAtRangeRule(min: 16, max: 255),
                RollingConsentFormScheduleCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
