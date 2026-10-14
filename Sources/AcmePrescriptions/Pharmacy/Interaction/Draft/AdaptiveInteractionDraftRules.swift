import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive interaction draft must pass. Check returns its problems, or none.
    protocol AdaptiveInteractionDraftRule {
        func check(_ item: AdaptiveInteractionDraft) -> [String]
    }

    final class AdaptiveInteractionDraftCodePrefixRule: AdaptiveInteractionDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveInteractionDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveInteractionDraftLabelLengthRule: AdaptiveInteractionDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveInteractionDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveInteractionDraftRequiredLabelRule: AdaptiveInteractionDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveInteractionDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveInteractionDraftSequenceRangeRule: AdaptiveInteractionDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveInteractionDraft) -> [String] {
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

    final class AdaptiveInteractionDraftArchivedGuardRule: AdaptiveInteractionDraftRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AdaptiveInteractionDraft) -> [String] {
            if item.archived && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class AdaptiveInteractionDraftExpiresAtRangeRule: AdaptiveInteractionDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveInteractionDraft) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive interaction draft.
    final class AdaptiveInteractionDraftValidator {
        var rules: [any AdaptiveInteractionDraftRule]

        init(rules: [any AdaptiveInteractionDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveInteractionDraft) -> [String] {
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

        func requireValid(_ item: AdaptiveInteractionDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveInteractionDraft]) -> [String: [String]] {
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

    static func defaultAdaptiveInteractionDraftValidator() -> AdaptiveInteractionDraftValidator {
        return AdaptiveInteractionDraftValidator(
            rules: [
                AdaptiveInteractionDraftCodePrefixRule(prefix: "REF"),
                AdaptiveInteractionDraftLabelLengthRule(maxLength: 120),
                AdaptiveInteractionDraftRequiredLabelRule(message: "adaptive interaction draft needs this field"),
                AdaptiveInteractionDraftSequenceRangeRule(min: 120, max: 3600),
                AdaptiveInteractionDraftArchivedGuardRule(limit: 16),
                AdaptiveInteractionDraftExpiresAtRangeRule(min: 16, max: 3600),
            ]
        )
    }
}
