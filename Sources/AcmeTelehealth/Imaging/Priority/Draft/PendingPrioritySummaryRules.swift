import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending priority summary must pass. Check returns its problems, or none.
    protocol PendingPrioritySummaryRule {
        func check(_ item: PendingPrioritySummary) -> [String]
    }

    final class PendingPrioritySummaryCodePrefixRule: PendingPrioritySummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingPrioritySummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingPrioritySummaryCreatedAtRangeRule: PendingPrioritySummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingPrioritySummary) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingPrioritySummaryMaximumRangeRule: PendingPrioritySummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingPrioritySummary) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingPrioritySummaryRequiredSummaryRule: PendingPrioritySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingPrioritySummary) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingPrioritySummarySummaryLengthRule: PendingPrioritySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingPrioritySummary) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending priority summary.
    final class PendingPrioritySummaryValidator {
        var rules: [any PendingPrioritySummaryRule]

        init(rules: [any PendingPrioritySummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingPrioritySummary) -> [String] {
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

        func requireValid(_ item: PendingPrioritySummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingPrioritySummary]) -> [String: [String]] {
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

    static func defaultPendingPrioritySummaryValidator() -> PendingPrioritySummaryValidator {
        return PendingPrioritySummaryValidator(
            rules: [
                PendingPrioritySummaryCodePrefixRule(prefix: "REF"),
                PendingPrioritySummaryCreatedAtRangeRule(min: 80, max: 1000),
                PendingPrioritySummaryMaximumRangeRule(min: 9.8, max: 856.2),
                PendingPrioritySummaryRequiredSummaryRule(message: "pending priority summary needs this field"),
                PendingPrioritySummarySummaryLengthRule(maxLength: 120),
            ]
        )
    }
}
