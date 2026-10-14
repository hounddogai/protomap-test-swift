import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted referral draft must pass. Check returns its problems, or none.
    protocol WeightedReferralDraftRule {
        func check(_ item: WeightedReferralDraft) -> [String]
    }

    final class WeightedReferralDraftVisibleGuardRule: WeightedReferralDraftRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WeightedReferralDraft) -> [String] {
            if item.visible && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class WeightedReferralDraftRequiredLabelRule: WeightedReferralDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferralDraftRequiredCodeRule: WeightedReferralDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferralDraftRequiredDiagnosisCodeRule: WeightedReferralDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferralDraft) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferralDraftNameLengthRule: WeightedReferralDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReferralDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted referral draft.
    final class WeightedReferralDraftValidator {
        var rules: [any WeightedReferralDraftRule]

        init(rules: [any WeightedReferralDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedReferralDraft) -> [String] {
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

        func requireValid(_ item: WeightedReferralDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedReferralDraft]) -> [String: [String]] {
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

    static func defaultWeightedReferralDraftValidator() -> WeightedReferralDraftValidator {
        return WeightedReferralDraftValidator(
            rules: [
                WeightedReferralDraftVisibleGuardRule(limit: 1000),
                WeightedReferralDraftRequiredLabelRule(message: "weighted referral draft needs a value"),
                WeightedReferralDraftRequiredCodeRule(message: "weighted referral draft needs an entry"),
                WeightedReferralDraftRequiredDiagnosisCodeRule(message: "weighted referral draft needs this field"),
                WeightedReferralDraftNameLengthRule(maxLength: 32),
            ]
        )
    }
}
