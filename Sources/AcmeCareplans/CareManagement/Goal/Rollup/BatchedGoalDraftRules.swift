import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched goal draft must pass. Check returns its problems, or none.
    protocol BatchedGoalDraftRule {
        func check(_ item: BatchedGoalDraft) -> [String]
    }

    final class BatchedGoalDraftRequiredRegionRule: BatchedGoalDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedGoalDraft) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedGoalDraftNameLengthRule: BatchedGoalDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedGoalDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedGoalDraftRequiredNameRule: BatchedGoalDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedGoalDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedGoalDraftMinimumRangeRule: BatchedGoalDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedGoalDraft) -> [String] {
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

    final class BatchedGoalDraftCodePrefixRule: BatchedGoalDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedGoalDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedGoalDraftRegionLengthRule: BatchedGoalDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedGoalDraft) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched goal draft.
    final class BatchedGoalDraftValidator {
        var rules: [any BatchedGoalDraftRule]

        init(rules: [any BatchedGoalDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedGoalDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedGoalDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedGoalDraft]) -> [String: [String]] {
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

    static func defaultBatchedGoalDraftValidator() -> BatchedGoalDraftValidator {
        return BatchedGoalDraftValidator(
            rules: [
                BatchedGoalDraftRequiredRegionRule(message: "batched goal draft needs an entry"),
                BatchedGoalDraftNameLengthRule(maxLength: 3600),
                BatchedGoalDraftRequiredNameRule(message: "batched goal draft needs an entry"),
                BatchedGoalDraftMinimumRangeRule(min: 0.1, max: 862.1),
                BatchedGoalDraftCodePrefixRule(prefix: "X"),
                BatchedGoalDraftRegionLengthRule(maxLength: 16),
            ]
        )
    }
}
