import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation entry must pass. Check returns its problems, or none.
    protocol IsolationEntryRule {
        func check(_ item: IsolationEntry) -> [String]
    }

    final class IsolationEntryRequiredCodeRule: IsolationEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationEntryLabelLengthRule: IsolationEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationEntry) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationEntryRequiredTitleRule: IsolationEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationEntryRequiredDescriptionRule: IsolationEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationEntry) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a isolation entry.
    final class IsolationEntryValidator {
        var rules: [any IsolationEntryRule]

        init(rules: [any IsolationEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationEntry]) -> [String: [String]] {
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

    static func defaultIsolationEntryValidator() -> IsolationEntryValidator {
        return IsolationEntryValidator(
            rules: [
                IsolationEntryRequiredCodeRule(message: "isolation entry needs an entry"),
                IsolationEntryLabelLengthRule(maxLength: 16),
                IsolationEntryRequiredTitleRule(message: "isolation entry needs an entry"),
                IsolationEntryRequiredDescriptionRule(message: "isolation entry needs an entry"),
            ]
        )
    }
}
