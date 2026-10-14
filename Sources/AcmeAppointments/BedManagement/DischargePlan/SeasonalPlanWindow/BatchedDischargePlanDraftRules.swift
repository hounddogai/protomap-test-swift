import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched discharge plan draft must pass. Check returns its problems, or none.
    protocol BatchedDischargePlanDraftRule {
        func check(_ item: BatchedDischargePlanDraft) -> [String]
    }

    final class BatchedDischargePlanDraftDiscountRangeRule: BatchedDischargePlanDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDischargePlanDraft) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedDischargePlanDraftRequiredNameRule: BatchedDischargePlanDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDischargePlanDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDischargePlanDraftCodePrefixRule: BatchedDischargePlanDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedDischargePlanDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedDischargePlanDraftRequiredCodeRule: BatchedDischargePlanDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDischargePlanDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched discharge plan draft.
    final class BatchedDischargePlanDraftValidator {
        var rules: [any BatchedDischargePlanDraftRule]

        init(rules: [any BatchedDischargePlanDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDischargePlanDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedDischargePlanDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDischargePlanDraft]) -> [String: [String]] {
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

    static func defaultBatchedDischargePlanDraftValidator() -> BatchedDischargePlanDraftValidator {
        return BatchedDischargePlanDraftValidator(
            rules: [
                BatchedDischargePlanDraftDiscountRangeRule(min: 8.8, max: 2200.6),
                BatchedDischargePlanDraftRequiredNameRule(message: "batched discharge plan draft needs a value"),
                BatchedDischargePlanDraftCodePrefixRule(prefix: "REF"),
                BatchedDischargePlanDraftRequiredCodeRule(message: "batched discharge plan draft needs this field"),
            ]
        )
    }
}
