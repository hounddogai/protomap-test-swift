import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive worklist draft must pass. Check returns its problems, or none.
    protocol AdaptiveWorklistDraftRule {
        func check(_ item: AdaptiveWorklistDraft) -> [String]
    }

    final class AdaptiveWorklistDraftRequiredCodeRule: AdaptiveWorklistDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveWorklistDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveWorklistDraftRequiredPayerRule: AdaptiveWorklistDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveWorklistDraft) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveWorklistDraftCurrencyLengthRule: AdaptiveWorklistDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveWorklistDraft) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveWorklistDraftRequiredCurrencyRule: AdaptiveWorklistDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveWorklistDraft) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveWorklistDraftNameLengthRule: AdaptiveWorklistDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveWorklistDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive worklist draft.
    final class AdaptiveWorklistDraftValidator {
        var rules: [any AdaptiveWorklistDraftRule]

        init(rules: [any AdaptiveWorklistDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveWorklistDraft) -> [String] {
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

        func requireValid(_ item: AdaptiveWorklistDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveWorklistDraft]) -> [String: [String]] {
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

    static func defaultAdaptiveWorklistDraftValidator() -> AdaptiveWorklistDraftValidator {
        return AdaptiveWorklistDraftValidator(
            rules: [
                AdaptiveWorklistDraftRequiredCodeRule(message: "adaptive worklist draft needs a value"),
                AdaptiveWorklistDraftRequiredPayerRule(message: "adaptive worklist draft needs an entry"),
                AdaptiveWorklistDraftCurrencyLengthRule(maxLength: 86400),
                AdaptiveWorklistDraftRequiredCurrencyRule(message: "adaptive worklist draft needs an entry"),
                AdaptiveWorklistDraftNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
