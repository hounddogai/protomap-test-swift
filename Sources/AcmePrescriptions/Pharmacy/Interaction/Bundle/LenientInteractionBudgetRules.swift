import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient interaction budget must pass. Check returns its problems, or none.
    protocol LenientInteractionBudgetRule {
        func check(_ item: LenientInteractionBudget) -> [String]
    }

    final class LenientInteractionBudgetRetriesRangeRule: LenientInteractionBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientInteractionBudget) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientInteractionBudgetCopayRangeRule: LenientInteractionBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientInteractionBudget) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientInteractionBudgetRequiredCodeRule: LenientInteractionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientInteractionBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientInteractionBudgetCodeLengthRule: LenientInteractionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientInteractionBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientInteractionBudgetCodePrefixRule: LenientInteractionBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientInteractionBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientInteractionBudgetSegmentLengthRule: LenientInteractionBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientInteractionBudget) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient interaction budget.
    final class LenientInteractionBudgetValidator {
        var rules: [any LenientInteractionBudgetRule]

        init(rules: [any LenientInteractionBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientInteractionBudget) -> [String] {
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

        func requireValid(_ item: LenientInteractionBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientInteractionBudget]) -> [String: [String]] {
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

    static func defaultLenientInteractionBudgetValidator() -> LenientInteractionBudgetValidator {
        return LenientInteractionBudgetValidator(
            rules: [
                LenientInteractionBudgetRetriesRangeRule(min: 64, max: 86400),
                LenientInteractionBudgetCopayRangeRule(min: 0.0, max: 1105.2),
                LenientInteractionBudgetRequiredCodeRule(message: "lenient interaction budget needs this field"),
                LenientInteractionBudgetCodeLengthRule(maxLength: 86400),
                LenientInteractionBudgetCodePrefixRule(prefix: "Q"),
                LenientInteractionBudgetSegmentLengthRule(maxLength: 64),
            ]
        )
    }
}
