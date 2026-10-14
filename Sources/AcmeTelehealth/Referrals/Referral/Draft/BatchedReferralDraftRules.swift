import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched referral draft must pass. Check returns its problems, or none.
    protocol BatchedReferralDraftRule {
        func check(_ item: BatchedReferralDraft) -> [String]
    }

    final class BatchedReferralDraftAllowedSourceRule: BatchedReferralDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedReferralDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is inconsistent"]
            }
            return []
        }
    }

    final class BatchedReferralDraftCodePrefixRule: BatchedReferralDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedReferralDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedReferralDraftRequiredLabelRule: BatchedReferralDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedReferralDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched referral draft.
    final class BatchedReferralDraftValidator {
        var rules: [any BatchedReferralDraftRule]

        init(rules: [any BatchedReferralDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedReferralDraft) -> [String] {
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

        func requireValid(_ item: BatchedReferralDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedReferralDraft]) -> [String: [String]] {
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

    static func defaultBatchedReferralDraftValidator() -> BatchedReferralDraftValidator {
        return BatchedReferralDraftValidator(
            rules: [
                BatchedReferralDraftAllowedSourceRule(allowed: ["rolling", "global", "scheduled"]),
                BatchedReferralDraftCodePrefixRule(prefix: "X"),
                BatchedReferralDraftRequiredLabelRule(message: "batched referral draft needs a value"),
            ]
        )
    }
}
