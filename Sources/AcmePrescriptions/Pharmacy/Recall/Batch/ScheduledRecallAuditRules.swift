import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a scheduled recall audit must pass. Check returns its problems, or none.
    protocol ScheduledRecallAuditRule {
        func check(_ item: ScheduledRecallAudit) -> [String]
    }

    final class ScheduledRecallAuditArchivedGuardRule: ScheduledRecallAuditRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ScheduledRecallAudit) -> [String] {
            if item.archived && (item.durationMinutes > limit) {
                return ["duration minutes \(item.durationMinutes) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class ScheduledRecallAuditMinimumRangeRule: ScheduledRecallAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRecallAudit) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledRecallAuditCodePrefixRule: ScheduledRecallAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledRecallAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled recall audit.
    final class ScheduledRecallAuditValidator {
        var rules: [any ScheduledRecallAuditRule]

        init(rules: [any ScheduledRecallAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledRecallAudit) -> [String] {
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

        func requireValid(_ item: ScheduledRecallAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledRecallAudit]) -> [String: [String]] {
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

    static func defaultScheduledRecallAuditValidator() -> ScheduledRecallAuditValidator {
        return ScheduledRecallAuditValidator(
            rules: [
                ScheduledRecallAuditArchivedGuardRule(limit: 3600),
                ScheduledRecallAuditMinimumRangeRule(min: 5.8, max: 3826.4),
                ScheduledRecallAuditCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
