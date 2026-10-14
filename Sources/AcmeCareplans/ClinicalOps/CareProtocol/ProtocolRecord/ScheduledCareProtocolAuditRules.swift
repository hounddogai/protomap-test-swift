import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled care protocol audit must pass. Check returns its problems, or none.
    protocol ScheduledCareProtocolAuditRule {
        func check(_ item: ScheduledCareProtocolAudit) -> [String]
    }

    final class ScheduledCareProtocolAuditClinicianIDLengthRule: ScheduledCareProtocolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolAudit) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolAuditAllowedChannelRule: ScheduledCareProtocolAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledCareProtocolAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is unknown"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolAuditArchivedGuardRule: ScheduledCareProtocolAuditRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ScheduledCareProtocolAudit) -> [String] {
            if item.archived && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolAuditScoreRangeRule: ScheduledCareProtocolAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCareProtocolAudit) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledCareProtocolAuditRequiredClinicianIDRule: ScheduledCareProtocolAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolAudit) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCareProtocolAuditCodeLengthRule: ScheduledCareProtocolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled care protocol audit.
    final class ScheduledCareProtocolAuditValidator {
        var rules: [any ScheduledCareProtocolAuditRule]

        init(rules: [any ScheduledCareProtocolAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCareProtocolAudit) -> [String] {
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

        func requireValid(_ item: ScheduledCareProtocolAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCareProtocolAudit]) -> [String: [String]] {
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

    static func defaultScheduledCareProtocolAuditValidator() -> ScheduledCareProtocolAuditValidator {
        return ScheduledCareProtocolAuditValidator(
            rules: [
                ScheduledCareProtocolAuditClinicianIDLengthRule(maxLength: 64),
                ScheduledCareProtocolAuditAllowedChannelRule(allowed: ["global", "seasonal", "global"]),
                ScheduledCareProtocolAuditArchivedGuardRule(limit: 4.1),
                ScheduledCareProtocolAuditScoreRangeRule(min: 9.8, max: 611.5),
                ScheduledCareProtocolAuditRequiredClinicianIDRule(
                    message: "scheduled care protocol audit needs an entry"
                ),
                ScheduledCareProtocolAuditCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
