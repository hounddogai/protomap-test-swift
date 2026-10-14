import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched eligibility audit must pass. Check returns its problems, or none.
    protocol BatchedEligibilityAuditRule {
        func check(_ item: BatchedEligibilityAudit) -> [String]
    }

    final class BatchedEligibilityAuditCodePrefixRule: BatchedEligibilityAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedEligibilityAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedEligibilityAuditRequiredNameRule: BatchedEligibilityAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedEligibilityAudit) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedEligibilityAuditRequiredCodeRule: BatchedEligibilityAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedEligibilityAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched eligibility audit.
    final class BatchedEligibilityAuditValidator {
        var rules: [any BatchedEligibilityAuditRule]

        init(rules: [any BatchedEligibilityAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedEligibilityAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedEligibilityAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedEligibilityAudit]) -> [String: [String]] {
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

    static func defaultBatchedEligibilityAuditValidator() -> BatchedEligibilityAuditValidator {
        return BatchedEligibilityAuditValidator(
            rules: [
                BatchedEligibilityAuditCodePrefixRule(prefix: "Q"),
                BatchedEligibilityAuditRequiredNameRule(message: "batched eligibility audit needs this field"),
                BatchedEligibilityAuditRequiredCodeRule(message: "batched eligibility audit needs a value"),
            ]
        )
    }
}
