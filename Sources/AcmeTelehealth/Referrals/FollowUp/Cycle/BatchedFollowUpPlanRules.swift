import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched follow up plan must pass. Check returns its problems, or none.
    protocol BatchedFollowUpPlanRule {
        func check(_ item: BatchedFollowUpPlan) -> [String]
    }

    final class BatchedFollowUpPlanCodePrefixRule: BatchedFollowUpPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedFollowUpPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedFollowUpPlanRequiredNameRule: BatchedFollowUpPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedFollowUpPlan) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedFollowUpPlanRequiredBedRule: BatchedFollowUpPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedFollowUpPlan) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched follow up plan.
    final class BatchedFollowUpPlanValidator {
        var rules: [any BatchedFollowUpPlanRule]

        init(rules: [any BatchedFollowUpPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedFollowUpPlan) -> [String] {
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

        func requireValid(_ item: BatchedFollowUpPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedFollowUpPlan]) -> [String: [String]] {
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

    static func defaultBatchedFollowUpPlanValidator() -> BatchedFollowUpPlanValidator {
        return BatchedFollowUpPlanValidator(
            rules: [
                BatchedFollowUpPlanCodePrefixRule(prefix: "ACM"),
                BatchedFollowUpPlanRequiredNameRule(message: "batched follow up plan needs an entry"),
                BatchedFollowUpPlanRequiredBedRule(message: "batched follow up plan needs an entry"),
            ]
        )
    }
}
