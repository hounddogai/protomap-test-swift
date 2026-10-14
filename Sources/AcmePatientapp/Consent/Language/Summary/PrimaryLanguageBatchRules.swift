import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary language batch must pass. Check returns its problems, or none.
    protocol PrimaryLanguageBatchRule {
        func check(_ item: PrimaryLanguageBatch) -> [String]
    }

    final class PrimaryLanguageBatchMarginRangeRule: PrimaryLanguageBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryLanguageBatch) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryLanguageBatchCostRangeRule: PrimaryLanguageBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryLanguageBatch) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryLanguageBatchRequiredNameRule: PrimaryLanguageBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryLanguageBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryLanguageBatchRequiredCodeRule: PrimaryLanguageBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryLanguageBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryLanguageBatchCategoryLengthRule: PrimaryLanguageBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryLanguageBatch) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryLanguageBatchCodeLengthRule: PrimaryLanguageBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryLanguageBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary language batch.
    final class PrimaryLanguageBatchValidator {
        var rules: [any PrimaryLanguageBatchRule]

        init(rules: [any PrimaryLanguageBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryLanguageBatch) -> [String] {
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

        func requireValid(_ item: PrimaryLanguageBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryLanguageBatch]) -> [String: [String]] {
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

    static func defaultPrimaryLanguageBatchValidator() -> PrimaryLanguageBatchValidator {
        return PrimaryLanguageBatchValidator(
            rules: [
                PrimaryLanguageBatchMarginRangeRule(min: 4.9, max: 1209.5),
                PrimaryLanguageBatchCostRangeRule(min: 5.2, max: 802.6),
                PrimaryLanguageBatchRequiredNameRule(message: "primary language batch needs an entry"),
                PrimaryLanguageBatchRequiredCodeRule(message: "primary language batch needs a value"),
                PrimaryLanguageBatchCategoryLengthRule(maxLength: 86400),
                PrimaryLanguageBatchCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
