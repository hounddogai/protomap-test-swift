import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual assessment entry must pass. Check returns its problems, or none.
    protocol ManualAssessmentEntryRule {
        func check(_ item: ManualAssessmentEntry) -> [String]
    }

    final class ManualAssessmentEntryTitleLengthRule: ManualAssessmentEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualAssessmentEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualAssessmentEntryRequiredSummaryRule: ManualAssessmentEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAssessmentEntry) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualAssessmentEntryCodePrefixRule: ManualAssessmentEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualAssessmentEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual assessment entry.
    final class ManualAssessmentEntryValidator {
        var rules: [any ManualAssessmentEntryRule]

        init(rules: [any ManualAssessmentEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualAssessmentEntry) -> [String] {
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

        func requireValid(_ item: ManualAssessmentEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualAssessmentEntry]) -> [String: [String]] {
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

    static func defaultManualAssessmentEntryValidator() -> ManualAssessmentEntryValidator {
        return ManualAssessmentEntryValidator(
            rules: [
                ManualAssessmentEntryTitleLengthRule(maxLength: 86400),
                ManualAssessmentEntryRequiredSummaryRule(message: "manual assessment entry needs an entry"),
                ManualAssessmentEntryCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
