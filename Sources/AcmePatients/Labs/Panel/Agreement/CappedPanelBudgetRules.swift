import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped panel budget must pass. Check returns its problems, or none.
    protocol CappedPanelBudgetRule {
        func check(_ item: CappedPanelBudget) -> [String]
    }

    final class CappedPanelBudgetTitleLengthRule: CappedPanelBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedPanelBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedPanelBudgetCodePrefixRule: CappedPanelBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedPanelBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedPanelBudgetExternalRefLengthRule: CappedPanelBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedPanelBudget) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedPanelBudgetLimitRangeRule: CappedPanelBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedPanelBudget) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedPanelBudgetAllowedLabelRule: CappedPanelBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedPanelBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    final class CappedPanelBudgetRequiredExternalRefRule: CappedPanelBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedPanelBudget) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped panel budget.
    final class CappedPanelBudgetValidator {
        var rules: [any CappedPanelBudgetRule]

        init(rules: [any CappedPanelBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedPanelBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedPanelBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedPanelBudget]) -> [String: [String]] {
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

    static func defaultCappedPanelBudgetValidator() -> CappedPanelBudgetValidator {
        return CappedPanelBudgetValidator(
            rules: [
                CappedPanelBudgetTitleLengthRule(maxLength: 255),
                CappedPanelBudgetCodePrefixRule(prefix: "X"),
                CappedPanelBudgetExternalRefLengthRule(maxLength: 64),
                CappedPanelBudgetLimitRangeRule(min: 64, max: 3600),
                CappedPanelBudgetAllowedLabelRule(allowed: ["legacy", "scheduled"]),
                CappedPanelBudgetRequiredExternalRefRule(message: "capped panel budget needs an entry"),
            ]
        )
    }
}
