import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted panel draft must pass. Check returns its problems, or none.
    protocol WeightedPanelDraftRule {
        func check(_ item: WeightedPanelDraft) -> [String]
    }

    final class WeightedPanelDraftRequiredSpecialtyRule: WeightedPanelDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedPanelDraft) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedPanelDraftSpecialtyLengthRule: WeightedPanelDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedPanelDraft) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedPanelDraftRequiredCodeRule: WeightedPanelDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedPanelDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted panel draft.
    final class WeightedPanelDraftValidator {
        var rules: [any WeightedPanelDraftRule]

        init(rules: [any WeightedPanelDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedPanelDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedPanelDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedPanelDraft]) -> [String: [String]] {
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

    static func defaultWeightedPanelDraftValidator() -> WeightedPanelDraftValidator {
        return WeightedPanelDraftValidator(
            rules: [
                WeightedPanelDraftRequiredSpecialtyRule(message: "weighted panel draft needs this field"),
                WeightedPanelDraftSpecialtyLengthRule(maxLength: 86400),
                WeightedPanelDraftRequiredCodeRule(message: "weighted panel draft needs an entry"),
            ]
        )
    }
}
