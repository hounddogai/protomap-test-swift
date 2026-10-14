import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient proxy entry must pass. Check returns its problems, or none.
    protocol LenientProxyEntryRule {
        func check(_ item: LenientProxyEntry) -> [String]
    }

    final class LenientProxyEntryRequiredLabelRule: LenientProxyEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProxyEntry) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProxyEntryRequiredCodeRule: LenientProxyEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProxyEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProxyEntryBudgetRangeRule: LenientProxyEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProxyEntry) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a lenient proxy entry.
    final class LenientProxyEntryValidator {
        var rules: [any LenientProxyEntryRule]

        init(rules: [any LenientProxyEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProxyEntry) -> [String] {
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

        func requireValid(_ item: LenientProxyEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProxyEntry]) -> [String: [String]] {
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

    static func defaultLenientProxyEntryValidator() -> LenientProxyEntryValidator {
        return LenientProxyEntryValidator(
            rules: [
                LenientProxyEntryRequiredLabelRule(message: "lenient proxy entry needs a value"),
                LenientProxyEntryRequiredCodeRule(message: "lenient proxy entry needs an entry"),
                LenientProxyEntryBudgetRangeRule(min: 8.8, max: 1964.2),
            ]
        )
    }
}
