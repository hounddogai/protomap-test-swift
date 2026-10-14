import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched eligibility draft must pass. Check returns its problems, or none.
    protocol BatchedEligibilityDraftRule {
        func check(_ item: BatchedEligibilityDraft) -> [String]
    }

    final class BatchedEligibilityDraftSummaryLengthRule: BatchedEligibilityDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedEligibilityDraft) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedEligibilityDraftCodePrefixRule: BatchedEligibilityDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedEligibilityDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedEligibilityDraftCodeLengthRule: BatchedEligibilityDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedEligibilityDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedEligibilityDraftCopayRangeRule: BatchedEligibilityDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedEligibilityDraft) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedEligibilityDraftRequiredTitleRule: BatchedEligibilityDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedEligibilityDraft) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedEligibilityDraftRequiredSummaryRule: BatchedEligibilityDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedEligibilityDraft) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched eligibility draft.
    final class BatchedEligibilityDraftValidator {
        var rules: [any BatchedEligibilityDraftRule]

        init(rules: [any BatchedEligibilityDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedEligibilityDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedEligibilityDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedEligibilityDraft]) -> [String: [String]] {
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

    static func defaultBatchedEligibilityDraftValidator() -> BatchedEligibilityDraftValidator {
        return BatchedEligibilityDraftValidator(
            rules: [
                BatchedEligibilityDraftSummaryLengthRule(maxLength: 16),
                BatchedEligibilityDraftCodePrefixRule(prefix: "X"),
                BatchedEligibilityDraftCodeLengthRule(maxLength: 255),
                BatchedEligibilityDraftCopayRangeRule(min: 9.4, max: 2112.1),
                BatchedEligibilityDraftRequiredTitleRule(message: "batched eligibility draft needs an entry"),
                BatchedEligibilityDraftRequiredSummaryRule(message: "batched eligibility draft needs this field"),
            ]
        )
    }
}
