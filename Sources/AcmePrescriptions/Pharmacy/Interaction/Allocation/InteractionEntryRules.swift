import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction entry must pass. Check returns its problems, or none.
    protocol InteractionEntryRule {
        func check(_ item: InteractionEntry) -> [String]
    }

    final class InteractionEntryCopayRangeRule: InteractionEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionEntry) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionEntryRequiredNameRule: InteractionEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionEntryCodePrefixRule: InteractionEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InteractionEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction entry.
    final class InteractionEntryValidator {
        var rules: [any InteractionEntryRule]

        init(rules: [any InteractionEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionEntry]) -> [String: [String]] {
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

    static func defaultInteractionEntryValidator() -> InteractionEntryValidator {
        return InteractionEntryValidator(
            rules: [
                InteractionEntryCopayRangeRule(min: 2.7, max: 468.8),
                InteractionEntryRequiredNameRule(message: "interaction entry needs this field"),
                InteractionEntryCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
