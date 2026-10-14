import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff summary must pass. Check returns its problems, or none.
    protocol HandoffSummaryRule {
        func check(_ item: HandoffSummary) -> [String]
    }

    final class HandoffSummaryRequiredCodeRule: HandoffSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffSummaryPatientRefLengthRule: HandoffSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffSummary) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffSummarySummaryLengthRule: HandoffSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffSummary) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffSummaryRequiredTitleRule: HandoffSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffSummaryCodePrefixRule: HandoffSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: HandoffSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class HandoffSummaryRequiredPatientRefRule: HandoffSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffSummary) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a handoff summary.
    final class HandoffSummaryValidator {
        var rules: [any HandoffSummaryRule]

        init(rules: [any HandoffSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffSummary]) -> [String: [String]] {
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

    static func defaultHandoffSummaryValidator() -> HandoffSummaryValidator {
        return HandoffSummaryValidator(
            rules: [
                HandoffSummaryRequiredCodeRule(message: "handoff summary needs this field"),
                HandoffSummaryPatientRefLengthRule(maxLength: 16),
                HandoffSummarySummaryLengthRule(maxLength: 16),
                HandoffSummaryRequiredTitleRule(message: "handoff summary needs this field"),
                HandoffSummaryCodePrefixRule(prefix: "X"),
                HandoffSummaryRequiredPatientRefRule(message: "handoff summary needs an entry"),
            ]
        )
    }
}
