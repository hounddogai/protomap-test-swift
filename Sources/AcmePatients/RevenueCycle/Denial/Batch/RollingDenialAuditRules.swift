import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling denial audit must pass. Check returns its problems, or none.
    protocol RollingDenialAuditRule {
        func check(_ item: RollingDenialAudit) -> [String]
    }

    final class RollingDenialAuditVisitMinutesRangeRule: RollingDenialAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingDenialAudit) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingDenialAuditRequiredCodeRule: RollingDenialAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDenialAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDenialAuditRequiredLabelRule: RollingDenialAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDenialAudit) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDenialAuditActiveGuardRule: RollingDenialAuditRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RollingDenialAudit) -> [String] {
            if item.active && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling denial audit.
    final class RollingDenialAuditValidator {
        var rules: [any RollingDenialAuditRule]

        init(rules: [any RollingDenialAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingDenialAudit) -> [String] {
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

        func requireValid(_ item: RollingDenialAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingDenialAudit]) -> [String: [String]] {
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

    static func defaultRollingDenialAuditValidator() -> RollingDenialAuditValidator {
        return RollingDenialAuditValidator(
            rules: [
                RollingDenialAuditVisitMinutesRangeRule(min: 255, max: 255),
                RollingDenialAuditRequiredCodeRule(message: "rolling denial audit needs a value"),
                RollingDenialAuditRequiredLabelRule(message: "rolling denial audit needs this field"),
                RollingDenialAuditActiveGuardRule(limit: 8.8),
            ]
        )
    }
}
