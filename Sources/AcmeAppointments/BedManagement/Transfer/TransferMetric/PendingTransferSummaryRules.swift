import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending transfer summary must pass. Check returns its problems, or none.
    protocol PendingTransferSummaryRule {
        func check(_ item: PendingTransferSummary) -> [String]
    }

    final class PendingTransferSummaryCodePrefixRule: PendingTransferSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingTransferSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingTransferSummaryAllowedLabelRule: PendingTransferSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingTransferSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class PendingTransferSummaryRequiredLabelRule: PendingTransferSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingTransferSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingTransferSummaryBudgetRangeRule: PendingTransferSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingTransferSummary) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingTransferSummaryLabelLengthRule: PendingTransferSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingTransferSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending transfer summary.
    final class PendingTransferSummaryValidator {
        var rules: [any PendingTransferSummaryRule]

        init(rules: [any PendingTransferSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingTransferSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingTransferSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingTransferSummary]) -> [String: [String]] {
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

    static func defaultPendingTransferSummaryValidator() -> PendingTransferSummaryValidator {
        return PendingTransferSummaryValidator(
            rules: [
                PendingTransferSummaryCodePrefixRule(prefix: "X"),
                PendingTransferSummaryAllowedLabelRule(allowed: ["lenient", "batched"]),
                PendingTransferSummaryRequiredLabelRule(message: "pending transfer summary needs this field"),
                PendingTransferSummaryBudgetRangeRule(min: 8.9, max: 2506.1),
                PendingTransferSummaryLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
