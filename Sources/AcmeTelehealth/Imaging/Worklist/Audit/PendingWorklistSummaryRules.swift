import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending worklist summary must pass. Check returns its problems, or none.
    protocol PendingWorklistSummaryRule {
        func check(_ item: PendingWorklistSummary) -> [String]
    }

    final class PendingWorklistSummaryRequiredReviewerRule: PendingWorklistSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingWorklistSummary) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingWorklistSummaryCodePrefixRule: PendingWorklistSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingWorklistSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingWorklistSummaryRequiredSummaryRule: PendingWorklistSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingWorklistSummary) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingWorklistSummarySummaryLengthRule: PendingWorklistSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingWorklistSummary) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingWorklistSummaryLabelLengthRule: PendingWorklistSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingWorklistSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingWorklistSummaryReviewerLengthRule: PendingWorklistSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingWorklistSummary) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending worklist summary.
    final class PendingWorklistSummaryValidator {
        var rules: [any PendingWorklistSummaryRule]

        init(rules: [any PendingWorklistSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingWorklistSummary) -> [String] {
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

        func requireValid(_ item: PendingWorklistSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingWorklistSummary]) -> [String: [String]] {
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

    static func defaultPendingWorklistSummaryValidator() -> PendingWorklistSummaryValidator {
        return PendingWorklistSummaryValidator(
            rules: [
                PendingWorklistSummaryRequiredReviewerRule(message: "pending worklist summary needs an entry"),
                PendingWorklistSummaryCodePrefixRule(prefix: "X"),
                PendingWorklistSummaryRequiredSummaryRule(message: "pending worklist summary needs a value"),
                PendingWorklistSummarySummaryLengthRule(maxLength: 80),
                PendingWorklistSummaryLabelLengthRule(maxLength: 3600),
                PendingWorklistSummaryReviewerLengthRule(maxLength: 86400),
            ]
        )
    }
}
