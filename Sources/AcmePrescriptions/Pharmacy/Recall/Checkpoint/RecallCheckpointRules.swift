import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall checkpoint must pass. Check returns its problems, or none.
    protocol RecallCheckpointRule {
        func check(_ item: RecallCheckpoint) -> [String]
    }

    final class RecallCheckpointCurrencyLengthRule: RecallCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallCheckpoint) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallCheckpointRequiredTitleRule: RecallCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallCheckpointCodeLengthRule: RecallCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallCheckpointEndsAtRangeRule: RecallCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallCheckpoint) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallCheckpointRequiredCurrencyRule: RecallCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallCheckpoint) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallCheckpointRequiredNameRule: RecallCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall checkpoint.
    final class RecallCheckpointValidator {
        var rules: [any RecallCheckpointRule]

        init(rules: [any RecallCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallCheckpoint) -> [String] {
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

        func requireValid(_ item: RecallCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallCheckpoint]) -> [String: [String]] {
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

    static func defaultRecallCheckpointValidator() -> RecallCheckpointValidator {
        return RecallCheckpointValidator(
            rules: [
                RecallCheckpointCurrencyLengthRule(maxLength: 3600),
                RecallCheckpointRequiredTitleRule(message: "recall checkpoint needs a value"),
                RecallCheckpointCodeLengthRule(maxLength: 3600),
                RecallCheckpointEndsAtRangeRule(min: 1000, max: 3600),
                RecallCheckpointRequiredCurrencyRule(message: "recall checkpoint needs a value"),
                RecallCheckpointRequiredNameRule(message: "recall checkpoint needs a value"),
            ]
        )
    }
}
