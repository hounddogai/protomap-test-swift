import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a default handoff draft must pass. Check returns its problems, or none.
    protocol DefaultHandoffDraftRule {
        func check(_ item: DefaultHandoffDraft) -> [String]
    }

    final class DefaultHandoffDraftRequiredTitleRule: DefaultHandoffDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultHandoffDraft) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultHandoffDraftCodePrefixRule: DefaultHandoffDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultHandoffDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultHandoffDraftMaximumRangeRule: DefaultHandoffDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultHandoffDraft) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a default handoff draft.
    final class DefaultHandoffDraftValidator {
        var rules: [any DefaultHandoffDraftRule]

        init(rules: [any DefaultHandoffDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultHandoffDraft) -> [String] {
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

        func requireValid(_ item: DefaultHandoffDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultHandoffDraft]) -> [String: [String]] {
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

    static func defaultDefaultHandoffDraftValidator() -> DefaultHandoffDraftValidator {
        return DefaultHandoffDraftValidator(
            rules: [
                DefaultHandoffDraftRequiredTitleRule(message: "default handoff draft needs a value"),
                DefaultHandoffDraftCodePrefixRule(prefix: "ACM"),
                DefaultHandoffDraftMaximumRangeRule(min: 9.7, max: 4264.2),
            ]
        )
    }
}
