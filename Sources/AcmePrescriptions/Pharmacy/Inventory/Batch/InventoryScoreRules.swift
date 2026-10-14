import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory score must pass. Check returns its problems, or none.
    protocol InventoryScoreRule {
        func check(_ item: InventoryScore) -> [String]
    }

    final class InventoryScoreRequiredCodeRule: InventoryScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryScoreLabelLengthRule: InventoryScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryScore) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryScoreRequiredTitleRule: InventoryScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryScoreNameLengthRule: InventoryScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryScore) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryScoreUpdatedAtRangeRule: InventoryScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InventoryScore) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a inventory score.
    final class InventoryScoreValidator {
        var rules: [any InventoryScoreRule]

        init(rules: [any InventoryScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryScore) -> [String] {
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

        func requireValid(_ item: InventoryScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryScore]) -> [String: [String]] {
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

    static func defaultInventoryScoreValidator() -> InventoryScoreValidator {
        return InventoryScoreValidator(
            rules: [
                InventoryScoreRequiredCodeRule(message: "inventory score needs this field"),
                InventoryScoreLabelLengthRule(maxLength: 64),
                InventoryScoreRequiredTitleRule(message: "inventory score needs a value"),
                InventoryScoreNameLengthRule(maxLength: 1000),
                InventoryScoreUpdatedAtRangeRule(min: 32, max: 3600),
            ]
        )
    }
}
