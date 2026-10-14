import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled care protocol schedule must pass. Check returns its problems, or none.
    protocol ScheduledCareProtocolScheduleRule {
        func check(_ item: ScheduledCareProtocolSchedule) -> [String]
    }

    final class ScheduledCareProtocolScheduleClinicianIDLengthRule: ScheduledCareProtocolScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolSchedule) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolScheduleCodeLengthRule: ScheduledCareProtocolScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolScheduleRequiredClinicianIDRule: ScheduledCareProtocolScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolSchedule) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCareProtocolScheduleCodePrefixRule: ScheduledCareProtocolScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledCareProtocolSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolScheduleAllowedCodeRule: ScheduledCareProtocolScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledCareProtocolSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled care protocol schedule.
    final class ScheduledCareProtocolScheduleValidator {
        var rules: [any ScheduledCareProtocolScheduleRule]

        init(rules: [any ScheduledCareProtocolScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCareProtocolSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCareProtocolSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCareProtocolSchedule]) -> [String: [String]] {
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

    static func defaultScheduledCareProtocolScheduleValidator() -> ScheduledCareProtocolScheduleValidator {
        return ScheduledCareProtocolScheduleValidator(
            rules: [
                ScheduledCareProtocolScheduleClinicianIDLengthRule(maxLength: 32),
                ScheduledCareProtocolScheduleCodeLengthRule(maxLength: 86400),
                ScheduledCareProtocolScheduleRequiredClinicianIDRule(
                    message: "scheduled care protocol schedule needs an entry"
                ),
                ScheduledCareProtocolScheduleCodePrefixRule(prefix: "OPS"),
                ScheduledCareProtocolScheduleAllowedCodeRule(allowed: ["manual", "strict", "regional"]),
            ]
        )
    }
}
