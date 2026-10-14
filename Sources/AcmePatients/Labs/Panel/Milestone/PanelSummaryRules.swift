import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel summary must pass. Check returns its problems, or none.
    protocol PanelSummaryRule {
        func check(_ item: PanelSummary) -> [String]
    }

    final class PanelSummaryRequiredTimezoneRule: PanelSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelSummary) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelSummaryRequiredTitleRule: PanelSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelSummaryRequiredCodeRule: PanelSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelSummaryLabelLengthRule: PanelSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelSummaryTitleLengthRule: PanelSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a panel summary.
    final class PanelSummaryValidator {
        var rules: [any PanelSummaryRule]

        init(rules: [any PanelSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelSummary) -> [String] {
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

        func requireValid(_ item: PanelSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelSummary]) -> [String: [String]] {
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

    static func defaultPanelSummaryValidator() -> PanelSummaryValidator {
        return PanelSummaryValidator(
            rules: [
                PanelSummaryRequiredTimezoneRule(message: "panel summary needs a value"),
                PanelSummaryRequiredTitleRule(message: "panel summary needs this field"),
                PanelSummaryRequiredCodeRule(message: "panel summary needs an entry"),
                PanelSummaryLabelLengthRule(maxLength: 64),
                PanelSummaryTitleLengthRule(maxLength: 32),
            ]
        )
    }
}
