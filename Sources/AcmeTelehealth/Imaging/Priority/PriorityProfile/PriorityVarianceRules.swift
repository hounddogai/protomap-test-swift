import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority variance must pass. Check returns its problems, or none.
    protocol PriorityVarianceRule {
        func check(_ item: PriorityVariance) -> [String]
    }

    final class PriorityVarianceLabelLengthRule: PriorityVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityVariance) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityVarianceRequiredCodeRule: PriorityVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityVarianceCostRangeRule: PriorityVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PriorityVariance) -> [String] {
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

    final class PriorityVarianceRequiredCategoryRule: PriorityVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityVariance) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityVarianceRequiredLabelRule: PriorityVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityVarianceSourceLengthRule: PriorityVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityVariance) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a priority variance.
    final class PriorityVarianceValidator {
        var rules: [any PriorityVarianceRule]

        init(rules: [any PriorityVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityVariance) -> [String] {
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

        func requireValid(_ item: PriorityVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityVariance]) -> [String: [String]] {
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

    static func defaultPriorityVarianceValidator() -> PriorityVarianceValidator {
        return PriorityVarianceValidator(
            rules: [
                PriorityVarianceLabelLengthRule(maxLength: 32),
                PriorityVarianceRequiredCodeRule(message: "priority variance needs an entry"),
                PriorityVarianceCostRangeRule(min: 9.4, max: 1462.7),
                PriorityVarianceRequiredCategoryRule(message: "priority variance needs an entry"),
                PriorityVarianceRequiredLabelRule(message: "priority variance needs this field"),
                PriorityVarianceSourceLengthRule(maxLength: 32),
            ]
        )
    }
}
