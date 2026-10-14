import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled follow up audit must pass. Check returns its problems, or none.
    protocol ScheduledFollowUpAuditRule {
        func check(_ item: ScheduledFollowUpAudit) -> [String]
    }

    final class ScheduledFollowUpAuditDiagnosisCodeLengthRule: ScheduledFollowUpAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFollowUpAudit) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpAuditTitleLengthRule: ScheduledFollowUpAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFollowUpAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpAuditEncounterIDLengthRule: ScheduledFollowUpAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFollowUpAudit) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpAuditRequiredEncounterIDRule: ScheduledFollowUpAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFollowUpAudit) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledFollowUpAuditRequiredTitleRule: ScheduledFollowUpAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFollowUpAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled follow up audit.
    final class ScheduledFollowUpAuditValidator {
        var rules: [any ScheduledFollowUpAuditRule]

        init(rules: [any ScheduledFollowUpAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledFollowUpAudit) -> [String] {
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

        func requireValid(_ item: ScheduledFollowUpAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledFollowUpAudit]) -> [String: [String]] {
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

    static func defaultScheduledFollowUpAuditValidator() -> ScheduledFollowUpAuditValidator {
        return ScheduledFollowUpAuditValidator(
            rules: [
                ScheduledFollowUpAuditDiagnosisCodeLengthRule(maxLength: 64),
                ScheduledFollowUpAuditTitleLengthRule(maxLength: 16),
                ScheduledFollowUpAuditEncounterIDLengthRule(maxLength: 80),
                ScheduledFollowUpAuditRequiredEncounterIDRule(message: "scheduled follow up audit needs an entry"),
                ScheduledFollowUpAuditRequiredTitleRule(message: "scheduled follow up audit needs this field"),
            ]
        )
    }
}
