import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure summary must pass. Check returns its problems, or none.
    protocol DisclosureSummaryRule {
        func check(_ item: DisclosureSummary) -> [String]
    }

    final class DisclosureSummaryRequiredCodeRule: DisclosureSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureSummaryRequiredLabelRule: DisclosureSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureSummaryLabelLengthRule: DisclosureSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureSummaryCreatedAtRangeRule: DisclosureSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureSummary) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosureSummaryCodePrefixRule: DisclosureSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure summary.
    final class DisclosureSummaryValidator {
        var rules: [any DisclosureSummaryRule]

        init(rules: [any DisclosureSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureSummary) -> [String] {
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

        func requireValid(_ item: DisclosureSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureSummary]) -> [String: [String]] {
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

    static func defaultDisclosureSummaryValidator() -> DisclosureSummaryValidator {
        return DisclosureSummaryValidator(
            rules: [
                DisclosureSummaryRequiredCodeRule(message: "disclosure summary needs an entry"),
                DisclosureSummaryRequiredLabelRule(message: "disclosure summary needs an entry"),
                DisclosureSummaryLabelLengthRule(maxLength: 120),
                DisclosureSummaryCreatedAtRangeRule(min: 255, max: 86400),
                DisclosureSummaryCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
