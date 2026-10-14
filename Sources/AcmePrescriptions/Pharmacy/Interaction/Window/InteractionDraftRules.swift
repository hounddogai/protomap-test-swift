import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction draft must pass. Check returns its problems, or none.
    protocol InteractionDraftRule {
        func check(_ item: InteractionDraft) -> [String]
    }

    final class InteractionDraftRequiredAllergyRule: InteractionDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionDraft) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionDraftApprovedGuardRule: InteractionDraftRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: InteractionDraft) -> [String] {
            if item.approved && (item.batchSize > limit) {
                return ["batch size \(item.batchSize) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class InteractionDraftLabelLengthRule: InteractionDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionDraft) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionDraftCodeLengthRule: InteractionDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionDraftRequiredCodeRule: InteractionDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction draft.
    final class InteractionDraftValidator {
        var rules: [any InteractionDraftRule]

        init(rules: [any InteractionDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionDraft]) -> [String: [String]] {
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

    static func defaultInteractionDraftValidator() -> InteractionDraftValidator {
        return InteractionDraftValidator(
            rules: [
                InteractionDraftRequiredAllergyRule(message: "interaction draft needs a value"),
                InteractionDraftApprovedGuardRule(limit: 80),
                InteractionDraftLabelLengthRule(maxLength: 80),
                InteractionDraftCodeLengthRule(maxLength: 120),
                InteractionDraftRequiredCodeRule(message: "interaction draft needs an entry"),
            ]
        )
    }
}
