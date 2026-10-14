import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert schedule must pass. Check returns its problems, or none.
    protocol AlertScheduleRule {
        func check(_ item: AlertSchedule) -> [String]
    }

    final class AlertScheduleSummaryLengthRule: AlertScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertSchedule) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertScheduleFacilityLengthRule: AlertScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertSchedule) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertScheduleAllowedPatientRefRule: AlertScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AlertSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is too long"]
            }
            return []
        }
    }

    final class AlertScheduleTitleLengthRule: AlertScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertSchedule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertScheduleRequiredFacilityRule: AlertScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertSchedule) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert schedule.
    final class AlertScheduleValidator {
        var rules: [any AlertScheduleRule]

        init(rules: [any AlertScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertSchedule]) -> [String: [String]] {
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

    static func defaultAlertScheduleValidator() -> AlertScheduleValidator {
        return AlertScheduleValidator(
            rules: [
                AlertScheduleSummaryLengthRule(maxLength: 3600),
                AlertScheduleFacilityLengthRule(maxLength: 86400),
                AlertScheduleAllowedPatientRefRule(allowed: ["primary", "regional", "capped"]),
                AlertScheduleTitleLengthRule(maxLength: 120),
                AlertScheduleRequiredFacilityRule(message: "alert schedule needs this field"),
            ]
        )
    }
}
