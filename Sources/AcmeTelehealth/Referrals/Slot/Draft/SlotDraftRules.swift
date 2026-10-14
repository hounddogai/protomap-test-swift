import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot draft must pass. Check returns its problems, or none.
    protocol SlotDraftRule {
        func check(_ item: SlotDraft) -> [String]
    }

    final class SlotDraftRequiredLabelRule: SlotDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotDraftCreatedAtRangeRule: SlotDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotDraft) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SlotDraftRequiredCodeRule: SlotDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotDraftRequiredLocaleRule: SlotDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotDraft) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotDraftAllowedLabelRule: SlotDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SlotDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a slot draft.
    final class SlotDraftValidator {
        var rules: [any SlotDraftRule]

        init(rules: [any SlotDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotDraft]) -> [String: [String]] {
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

    static func defaultSlotDraftValidator() -> SlotDraftValidator {
        return SlotDraftValidator(
            rules: [
                SlotDraftRequiredLabelRule(message: "slot draft needs an entry"),
                SlotDraftCreatedAtRangeRule(min: 255, max: 1000),
                SlotDraftRequiredCodeRule(message: "slot draft needs this field"),
                SlotDraftRequiredLocaleRule(message: "slot draft needs this field"),
                SlotDraftAllowedLabelRule(allowed: []),
            ]
        )
    }
}
