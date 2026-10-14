import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap draft must pass. Check returns its problems, or none.
    protocol CareGapDraftRule {
        func check(_ item: CareGapDraft) -> [String]
    }

    final class CareGapDraftAllowedCodeRule: CareGapDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class CareGapDraftTitleLengthRule: CareGapDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapDraft) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapDraftRequiredAllergyRule: CareGapDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapDraft) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care gap draft.
    final class CareGapDraftValidator {
        var rules: [any CareGapDraftRule]

        init(rules: [any CareGapDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapDraft]) -> [String: [String]] {
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

    static func defaultCareGapDraftValidator() -> CareGapDraftValidator {
        return CareGapDraftValidator(
            rules: [
                CareGapDraftAllowedCodeRule(allowed: ["regional"]),
                CareGapDraftTitleLengthRule(maxLength: 80),
                CareGapDraftRequiredAllergyRule(message: "care gap draft needs an entry"),
            ]
        )
    }
}
