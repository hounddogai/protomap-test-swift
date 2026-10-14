import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a default rounding draft must pass. Check returns its problems, or none.
    protocol DefaultRoundingDraftRule {
        func check(_ item: DefaultRoundingDraft) -> [String]
    }

    final class DefaultRoundingDraftDescriptionLengthRule: DefaultRoundingDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRoundingDraft) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRoundingDraftRequiredCodeRule: DefaultRoundingDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRoundingDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRoundingDraftAllowedCodeRule: DefaultRoundingDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultRoundingDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a default rounding draft.
    final class DefaultRoundingDraftValidator {
        var rules: [any DefaultRoundingDraftRule]

        init(rules: [any DefaultRoundingDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRoundingDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultRoundingDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRoundingDraft]) -> [String: [String]] {
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

    static func defaultDefaultRoundingDraftValidator() -> DefaultRoundingDraftValidator {
        return DefaultRoundingDraftValidator(
            rules: [
                DefaultRoundingDraftDescriptionLengthRule(maxLength: 255),
                DefaultRoundingDraftRequiredCodeRule(message: "default rounding draft needs a value"),
                DefaultRoundingDraftAllowedCodeRule(allowed: ["weighted", "lenient", "adaptive"]),
            ]
        )
    }
}
