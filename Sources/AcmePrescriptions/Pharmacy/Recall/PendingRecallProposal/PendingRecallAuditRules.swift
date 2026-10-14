import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending recall audit must pass. Check returns its problems, or none.
    protocol PendingRecallAuditRule {
        func check(_ item: PendingRecallAudit) -> [String]
    }

    final class PendingRecallAuditVisitMinutesRangeRule: PendingRecallAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRecallAudit) -> [String] {
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

    final class PendingRecallAuditRetriesRangeRule: PendingRecallAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRecallAudit) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingRecallAuditWardLengthRule: PendingRecallAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRecallAudit) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRecallAuditAllowedWardRule: PendingRecallAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingRecallAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is below minimum"]
            }
            return []
        }
    }

    final class PendingRecallAuditRequiredTitleRule: PendingRecallAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRecallAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRecallAuditCodeLengthRule: PendingRecallAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRecallAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending recall audit.
    final class PendingRecallAuditValidator {
        var rules: [any PendingRecallAuditRule]

        init(rules: [any PendingRecallAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRecallAudit) -> [String] {
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

        func requireValid(_ item: PendingRecallAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRecallAudit]) -> [String: [String]] {
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

    static func defaultPendingRecallAuditValidator() -> PendingRecallAuditValidator {
        return PendingRecallAuditValidator(
            rules: [
                PendingRecallAuditVisitMinutesRangeRule(min: 32, max: 120),
                PendingRecallAuditRetriesRangeRule(min: 32, max: 1000),
                PendingRecallAuditWardLengthRule(maxLength: 3600),
                PendingRecallAuditAllowedWardRule(allowed: ["seasonal", "weighted", "primary"]),
                PendingRecallAuditRequiredTitleRule(message: "pending recall audit needs an entry"),
                PendingRecallAuditCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
