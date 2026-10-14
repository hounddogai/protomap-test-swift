import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted recall draft must pass. Check returns its problems, or none.
    protocol WeightedRecallDraftRule {
        func check(_ item: WeightedRecallDraft) -> [String]
    }

    final class WeightedRecallDraftAllowedLabelRule: WeightedRecallDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedRecallDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class WeightedRecallDraftRequiredCodeRule: WeightedRecallDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRecallDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRecallDraftRequiredNameRule: WeightedRecallDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRecallDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted recall draft.
    final class WeightedRecallDraftValidator {
        var rules: [any WeightedRecallDraftRule]

        init(rules: [any WeightedRecallDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRecallDraft) -> [String] {
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

        func requireValid(_ item: WeightedRecallDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRecallDraft]) -> [String: [String]] {
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

    static func defaultWeightedRecallDraftValidator() -> WeightedRecallDraftValidator {
        return WeightedRecallDraftValidator(
            rules: [
                WeightedRecallDraftAllowedLabelRule(allowed: []),
                WeightedRecallDraftRequiredCodeRule(message: "weighted recall draft needs an entry"),
                WeightedRecallDraftRequiredNameRule(message: "weighted recall draft needs a value"),
            ]
        )
    }
}
