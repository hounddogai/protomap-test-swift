import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback claim draft must pass. Check returns its problems, or none.
    protocol FallbackClaimDraftRule {
        func check(_ item: FallbackClaimDraft) -> [String]
    }

    final class FallbackClaimDraftRequiredCodeRule: FallbackClaimDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackClaimDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackClaimDraftStartsAtRangeRule: FallbackClaimDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackClaimDraft) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackClaimDraftQuantityRangeRule: FallbackClaimDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackClaimDraft) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackClaimDraftCodePrefixRule: FallbackClaimDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackClaimDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackClaimDraftRequiredTitleRule: FallbackClaimDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackClaimDraft) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback claim draft.
    final class FallbackClaimDraftValidator {
        var rules: [any FallbackClaimDraftRule]

        init(rules: [any FallbackClaimDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackClaimDraft) -> [String] {
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

        func requireValid(_ item: FallbackClaimDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackClaimDraft]) -> [String: [String]] {
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

    static func defaultFallbackClaimDraftValidator() -> FallbackClaimDraftValidator {
        return FallbackClaimDraftValidator(
            rules: [
                FallbackClaimDraftRequiredCodeRule(message: "fallback claim draft needs a value"),
                FallbackClaimDraftStartsAtRangeRule(min: 16, max: 3600),
                FallbackClaimDraftQuantityRangeRule(min: 32, max: 1000),
                FallbackClaimDraftCodePrefixRule(prefix: "Q"),
                FallbackClaimDraftRequiredTitleRule(message: "fallback claim draft needs this field"),
            ]
        )
    }
}
