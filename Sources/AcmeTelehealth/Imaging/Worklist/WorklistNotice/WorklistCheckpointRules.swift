import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist checkpoint must pass. Check returns its problems, or none.
    protocol WorklistCheckpointRule {
        func check(_ item: WorklistCheckpoint) -> [String]
    }

    final class WorklistCheckpointCurrencyLengthRule: WorklistCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistCheckpoint) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistCheckpointRequiredCurrencyRule: WorklistCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistCheckpoint) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistCheckpointRequiredLabelRule: WorklistCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistCheckpointCodeLengthRule: WorklistCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist checkpoint.
    final class WorklistCheckpointValidator {
        var rules: [any WorklistCheckpointRule]

        init(rules: [any WorklistCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistCheckpoint) -> [String] {
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

        func requireValid(_ item: WorklistCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistCheckpoint]) -> [String: [String]] {
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

    static func defaultWorklistCheckpointValidator() -> WorklistCheckpointValidator {
        return WorklistCheckpointValidator(
            rules: [
                WorklistCheckpointCurrencyLengthRule(maxLength: 80),
                WorklistCheckpointRequiredCurrencyRule(message: "worklist checkpoint needs an entry"),
                WorklistCheckpointRequiredLabelRule(message: "worklist checkpoint needs this field"),
                WorklistCheckpointCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
