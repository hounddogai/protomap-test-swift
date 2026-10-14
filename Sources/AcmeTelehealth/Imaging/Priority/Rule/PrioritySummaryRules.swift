import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority summary must pass. Check returns its problems, or none.
    protocol PrioritySummaryRule {
        func check(_ item: PrioritySummary) -> [String]
    }

    final class PrioritySummaryCodeLengthRule: PrioritySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrioritySummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrioritySummaryNotesLengthRule: PrioritySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrioritySummary) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrioritySummaryRequiredNotesRule: PrioritySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrioritySummary) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a priority summary.
    final class PrioritySummaryValidator {
        var rules: [any PrioritySummaryRule]

        init(rules: [any PrioritySummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: PrioritySummary) -> [String] {
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

        func requireValid(_ item: PrioritySummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrioritySummary]) -> [String: [String]] {
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

    static func defaultPrioritySummaryValidator() -> PrioritySummaryValidator {
        return PrioritySummaryValidator(
            rules: [
                PrioritySummaryCodeLengthRule(maxLength: 80),
                PrioritySummaryNotesLengthRule(maxLength: 86400),
                PrioritySummaryRequiredNotesRule(message: "priority summary needs this field"),
            ]
        )
    }
}
