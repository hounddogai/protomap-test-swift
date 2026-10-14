import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive overtime budget must pass. Check returns its problems, or none.
    protocol AdaptiveOvertimeBudgetRule {
        func check(_ item: AdaptiveOvertimeBudget) -> [String]
    }

    final class AdaptiveOvertimeBudgetCodePrefixRule: AdaptiveOvertimeBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveOvertimeBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveOvertimeBudgetRequiredNotesRule: AdaptiveOvertimeBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveOvertimeBudget) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveOvertimeBudgetNotesLengthRule: AdaptiveOvertimeBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveOvertimeBudget) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveOvertimeBudgetCreatedAtRangeRule: AdaptiveOvertimeBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveOvertimeBudget) -> [String] {
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

    final class AdaptiveOvertimeBudgetAllowedNotesRule: AdaptiveOvertimeBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveOvertimeBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is above maximum"]
            }
            return []
        }
    }

    final class AdaptiveOvertimeBudgetRequiredLabelRule: AdaptiveOvertimeBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveOvertimeBudget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive overtime budget.
    final class AdaptiveOvertimeBudgetValidator {
        var rules: [any AdaptiveOvertimeBudgetRule]

        init(rules: [any AdaptiveOvertimeBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveOvertimeBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveOvertimeBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveOvertimeBudget]) -> [String: [String]] {
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

    static func defaultAdaptiveOvertimeBudgetValidator() -> AdaptiveOvertimeBudgetValidator {
        return AdaptiveOvertimeBudgetValidator(
            rules: [
                AdaptiveOvertimeBudgetCodePrefixRule(prefix: "REF"),
                AdaptiveOvertimeBudgetRequiredNotesRule(message: "adaptive overtime budget needs an entry"),
                AdaptiveOvertimeBudgetNotesLengthRule(maxLength: 3600),
                AdaptiveOvertimeBudgetCreatedAtRangeRule(min: 1000, max: 86400),
                AdaptiveOvertimeBudgetAllowedNotesRule(allowed: []),
                AdaptiveOvertimeBudgetRequiredLabelRule(message: "adaptive overtime budget needs a value"),
            ]
        )
    }
}
