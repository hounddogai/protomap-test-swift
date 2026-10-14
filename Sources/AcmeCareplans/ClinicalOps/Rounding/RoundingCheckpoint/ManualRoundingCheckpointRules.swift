import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual rounding checkpoint must pass. Check returns its problems, or none.
    protocol ManualRoundingCheckpointRule {
        func check(_ item: ManualRoundingCheckpoint) -> [String]
    }

    final class ManualRoundingCheckpointRequiredNameRule: ManualRoundingCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRoundingCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRoundingCheckpointRequiredCodeRule: ManualRoundingCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRoundingCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRoundingCheckpointRequiredTitleRule: ManualRoundingCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRoundingCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRoundingCheckpointDiscountRangeRule: ManualRoundingCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRoundingCheckpoint) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualRoundingCheckpointCodeLengthRule: ManualRoundingCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRoundingCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual rounding checkpoint.
    final class ManualRoundingCheckpointValidator {
        var rules: [any ManualRoundingCheckpointRule]

        init(rules: [any ManualRoundingCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRoundingCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualRoundingCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRoundingCheckpoint]) -> [String: [String]] {
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

    static func defaultManualRoundingCheckpointValidator() -> ManualRoundingCheckpointValidator {
        return ManualRoundingCheckpointValidator(
            rules: [
                ManualRoundingCheckpointRequiredNameRule(message: "manual rounding checkpoint needs an entry"),
                ManualRoundingCheckpointRequiredCodeRule(message: "manual rounding checkpoint needs an entry"),
                ManualRoundingCheckpointRequiredTitleRule(message: "manual rounding checkpoint needs a value"),
                ManualRoundingCheckpointDiscountRangeRule(min: 6.0, max: 597.9),
                ManualRoundingCheckpointCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
