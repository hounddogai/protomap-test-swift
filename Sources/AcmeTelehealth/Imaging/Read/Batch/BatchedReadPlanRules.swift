import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a batched read plan must pass. Check returns its problems, or none.
    protocol BatchedReadPlanRule {
        func check(_ item: BatchedReadPlan) -> [String]
    }

    final class BatchedReadPlanRequiredNotesRule: BatchedReadPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedReadPlan) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedReadPlanRequiredNameRule: BatchedReadPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedReadPlan) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedReadPlanRequiredLabelRule: BatchedReadPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedReadPlan) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedReadPlanAllowedWardRule: BatchedReadPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedReadPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is below minimum"]
            }
            return []
        }
    }

    final class BatchedReadPlanRequiredCodeRule: BatchedReadPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedReadPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched read plan.
    final class BatchedReadPlanValidator {
        var rules: [any BatchedReadPlanRule]

        init(rules: [any BatchedReadPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedReadPlan) -> [String] {
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

        func requireValid(_ item: BatchedReadPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedReadPlan]) -> [String: [String]] {
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

    static func defaultBatchedReadPlanValidator() -> BatchedReadPlanValidator {
        return BatchedReadPlanValidator(
            rules: [
                BatchedReadPlanRequiredNotesRule(message: "batched read plan needs a value"),
                BatchedReadPlanRequiredNameRule(message: "batched read plan needs an entry"),
                BatchedReadPlanRequiredLabelRule(message: "batched read plan needs a value"),
                BatchedReadPlanAllowedWardRule(allowed: []),
                BatchedReadPlanRequiredCodeRule(message: "batched read plan needs this field"),
            ]
        )
    }
}
