import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a seasonal interaction checkpoint must pass. Check returns its problems, or none.
    protocol SeasonalInteractionCheckpointRule {
        func check(_ item: SeasonalInteractionCheckpoint) -> [String]
    }

    final class SeasonalInteractionCheckpointRequiredLabelRule: SeasonalInteractionCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalInteractionCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalInteractionCheckpointAmountRangeRule: SeasonalInteractionCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalInteractionCheckpoint) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalInteractionCheckpointCategoryLengthRule: SeasonalInteractionCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalInteractionCheckpoint) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalInteractionCheckpointLabelLengthRule: SeasonalInteractionCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalInteractionCheckpoint) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalInteractionCheckpointAllowedCodeRule: SeasonalInteractionCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalInteractionCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal interaction checkpoint.
    final class SeasonalInteractionCheckpointValidator {
        var rules: [any SeasonalInteractionCheckpointRule]

        init(rules: [any SeasonalInteractionCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalInteractionCheckpoint) -> [String] {
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

        func requireValid(_ item: SeasonalInteractionCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalInteractionCheckpoint]) -> [String: [String]] {
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

    static func defaultSeasonalInteractionCheckpointValidator() -> SeasonalInteractionCheckpointValidator {
        return SeasonalInteractionCheckpointValidator(
            rules: [
                SeasonalInteractionCheckpointRequiredLabelRule(
                    message: "seasonal interaction checkpoint needs this field"
                ),
                SeasonalInteractionCheckpointAmountRangeRule(min: 1.5, max: 3477.9),
                SeasonalInteractionCheckpointCategoryLengthRule(maxLength: 120),
                SeasonalInteractionCheckpointLabelLengthRule(maxLength: 1000),
                SeasonalInteractionCheckpointAllowedCodeRule(allowed: []),
            ]
        )
    }
}
