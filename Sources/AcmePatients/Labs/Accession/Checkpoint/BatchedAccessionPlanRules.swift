import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched accession plan must pass. Check returns its problems, or none.
    protocol BatchedAccessionPlanRule {
        func check(_ item: BatchedAccessionPlan) -> [String]
    }

    final class BatchedAccessionPlanRequiredCodeRule: BatchedAccessionPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAccessionPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAccessionPlanThresholdRangeRule: BatchedAccessionPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedAccessionPlan) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedAccessionPlanCodePrefixRule: BatchedAccessionPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedAccessionPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedAccessionPlanRequiredOwnerIDRule: BatchedAccessionPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAccessionPlan) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAccessionPlanRequiredDescriptionRule: BatchedAccessionPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAccessionPlan) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAccessionPlanOwnerIDLengthRule: BatchedAccessionPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAccessionPlan) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched accession plan.
    final class BatchedAccessionPlanValidator {
        var rules: [any BatchedAccessionPlanRule]

        init(rules: [any BatchedAccessionPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedAccessionPlan) -> [String] {
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

        func requireValid(_ item: BatchedAccessionPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedAccessionPlan]) -> [String: [String]] {
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

    static func defaultBatchedAccessionPlanValidator() -> BatchedAccessionPlanValidator {
        return BatchedAccessionPlanValidator(
            rules: [
                BatchedAccessionPlanRequiredCodeRule(message: "batched accession plan needs an entry"),
                BatchedAccessionPlanThresholdRangeRule(min: 8.1, max: 4774.7),
                BatchedAccessionPlanCodePrefixRule(prefix: "OPS"),
                BatchedAccessionPlanRequiredOwnerIDRule(message: "batched accession plan needs a value"),
                BatchedAccessionPlanRequiredDescriptionRule(message: "batched accession plan needs this field"),
                BatchedAccessionPlanOwnerIDLengthRule(maxLength: 1000),
            ]
        )
    }
}
