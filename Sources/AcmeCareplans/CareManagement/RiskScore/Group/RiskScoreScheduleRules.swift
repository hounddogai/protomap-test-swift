import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score schedule must pass. Check returns its problems, or none.
    protocol RiskScoreScheduleRule {
        func check(_ item: RiskScoreSchedule) -> [String]
    }

    final class RiskScoreSchedulePatientRefLengthRule: RiskScoreScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreSchedule) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreScheduleRequiredCodeRule: RiskScoreScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreScheduleExpiresAtRangeRule: RiskScoreScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreSchedule) -> [String] {
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

    final class RiskScoreScheduleRequiredBedRule: RiskScoreScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreSchedule) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a risk score schedule.
    final class RiskScoreScheduleValidator {
        var rules: [any RiskScoreScheduleRule]

        init(rules: [any RiskScoreScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreSchedule]) -> [String: [String]] {
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

    static func defaultRiskScoreScheduleValidator() -> RiskScoreScheduleValidator {
        return RiskScoreScheduleValidator(
            rules: [
                RiskScoreSchedulePatientRefLengthRule(maxLength: 120),
                RiskScoreScheduleRequiredCodeRule(message: "risk score schedule needs a value"),
                RiskScoreScheduleExpiresAtRangeRule(min: 16, max: 80),
                RiskScoreScheduleRequiredBedRule(message: "risk score schedule needs an entry"),
            ]
        )
    }
}
