import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist audit must pass. Check returns its problems, or none.
    protocol WorklistAuditRule {
        func check(_ item: WorklistAudit) -> [String]
    }

    final class WorklistAuditSequenceRangeRule: WorklistAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistAudit) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WorklistAuditCodePrefixRule: WorklistAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WorklistAuditQuantityRangeRule: WorklistAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistAudit) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistAuditRequiredCodeRule: WorklistAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistAuditApprovedGuardRule: WorklistAuditRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WorklistAudit) -> [String] {
            if item.approved && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist audit.
    final class WorklistAuditValidator {
        var rules: [any WorklistAuditRule]

        init(rules: [any WorklistAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistAudit]) -> [String: [String]] {
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

    static func defaultWorklistAuditValidator() -> WorklistAuditValidator {
        return WorklistAuditValidator(
            rules: [
                WorklistAuditSequenceRangeRule(min: 16, max: 1000),
                WorklistAuditCodePrefixRule(prefix: "REF"),
                WorklistAuditQuantityRangeRule(min: 80, max: 86400),
                WorklistAuditRequiredCodeRule(message: "worklist audit needs an entry"),
                WorklistAuditApprovedGuardRule(limit: 3600),
            ]
        )
    }
}
