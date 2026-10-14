import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive formulary draft must pass. Check returns its problems, or none.
    protocol AdaptiveFormularyDraftRule {
        func check(_ item: AdaptiveFormularyDraft) -> [String]
    }

    final class AdaptiveFormularyDraftRevisionRangeRule: AdaptiveFormularyDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFormularyDraft) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveFormularyDraftAllowedCodeRule: AdaptiveFormularyDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveFormularyDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class AdaptiveFormularyDraftRequiredPayerRule: AdaptiveFormularyDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveFormularyDraft) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveFormularyDraftTitleLengthRule: AdaptiveFormularyDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveFormularyDraft) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveFormularyDraftPayerLengthRule: AdaptiveFormularyDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveFormularyDraft) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveFormularyDraftPriorityRangeRule: AdaptiveFormularyDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFormularyDraft) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive formulary draft.
    final class AdaptiveFormularyDraftValidator {
        var rules: [any AdaptiveFormularyDraftRule]

        init(rules: [any AdaptiveFormularyDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveFormularyDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveFormularyDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveFormularyDraft]) -> [String: [String]] {
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

    static func defaultAdaptiveFormularyDraftValidator() -> AdaptiveFormularyDraftValidator {
        return AdaptiveFormularyDraftValidator(
            rules: [
                AdaptiveFormularyDraftRevisionRangeRule(min: 3600, max: 86400),
                AdaptiveFormularyDraftAllowedCodeRule(allowed: ["tiered", "rolling"]),
                AdaptiveFormularyDraftRequiredPayerRule(message: "adaptive formulary draft needs an entry"),
                AdaptiveFormularyDraftTitleLengthRule(maxLength: 86400),
                AdaptiveFormularyDraftPayerLengthRule(maxLength: 32),
                AdaptiveFormularyDraftPriorityRangeRule(min: 32, max: 120),
            ]
        )
    }
}
