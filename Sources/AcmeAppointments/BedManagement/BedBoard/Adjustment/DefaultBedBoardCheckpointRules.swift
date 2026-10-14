import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default bed board checkpoint must pass. Check returns its problems, or none.
    protocol DefaultBedBoardCheckpointRule {
        func check(_ item: DefaultBedBoardCheckpoint) -> [String]
    }

    final class DefaultBedBoardCheckpointRequiredNameRule: DefaultBedBoardCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultBedBoardCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultBedBoardCheckpointCodePrefixRule: DefaultBedBoardCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultBedBoardCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultBedBoardCheckpointBudgetRangeRule: DefaultBedBoardCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultBedBoardCheckpoint) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultBedBoardCheckpointNameLengthRule: DefaultBedBoardCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultBedBoardCheckpoint) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default bed board checkpoint.
    final class DefaultBedBoardCheckpointValidator {
        var rules: [any DefaultBedBoardCheckpointRule]

        init(rules: [any DefaultBedBoardCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultBedBoardCheckpoint) -> [String] {
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

        func requireValid(_ item: DefaultBedBoardCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultBedBoardCheckpoint]) -> [String: [String]] {
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

    static func defaultDefaultBedBoardCheckpointValidator() -> DefaultBedBoardCheckpointValidator {
        return DefaultBedBoardCheckpointValidator(
            rules: [
                DefaultBedBoardCheckpointRequiredNameRule(message: "default bed board checkpoint needs an entry"),
                DefaultBedBoardCheckpointCodePrefixRule(prefix: "Q"),
                DefaultBedBoardCheckpointBudgetRangeRule(min: 3.9, max: 3063.0),
                DefaultBedBoardCheckpointNameLengthRule(maxLength: 86400),
            ]
        )
    }
}
