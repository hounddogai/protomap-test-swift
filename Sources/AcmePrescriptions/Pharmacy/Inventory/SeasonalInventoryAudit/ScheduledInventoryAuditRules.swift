import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a scheduled inventory audit must pass. Check returns its problems, or none.
    protocol ScheduledInventoryAuditRule {
        func check(_ item: ScheduledInventoryAudit) -> [String]
    }

    final class ScheduledInventoryAuditRequiredCodeRule: ScheduledInventoryAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledInventoryAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledInventoryAuditTitleLengthRule: ScheduledInventoryAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledInventoryAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledInventoryAuditMinimumRangeRule: ScheduledInventoryAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledInventoryAudit) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled inventory audit.
    final class ScheduledInventoryAuditValidator {
        var rules: [any ScheduledInventoryAuditRule]

        init(rules: [any ScheduledInventoryAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledInventoryAudit) -> [String] {
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

        func requireValid(_ item: ScheduledInventoryAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledInventoryAudit]) -> [String: [String]] {
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

    static func defaultScheduledInventoryAuditValidator() -> ScheduledInventoryAuditValidator {
        return ScheduledInventoryAuditValidator(
            rules: [
                ScheduledInventoryAuditRequiredCodeRule(message: "scheduled inventory audit needs an entry"),
                ScheduledInventoryAuditTitleLengthRule(maxLength: 3600),
                ScheduledInventoryAuditMinimumRangeRule(min: 8.8, max: 4041.5),
            ]
        )
    }
}
