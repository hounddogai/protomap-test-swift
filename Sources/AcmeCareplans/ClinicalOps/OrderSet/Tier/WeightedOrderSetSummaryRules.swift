import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a weighted order set summary must pass. Check returns its problems, or none.
    protocol WeightedOrderSetSummaryRule {
        func check(_ item: WeightedOrderSetSummary) -> [String]
    }

    final class WeightedOrderSetSummaryRequiredSourceRule: WeightedOrderSetSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedOrderSetSummary) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedOrderSetSummaryCodeLengthRule: WeightedOrderSetSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedOrderSetSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedOrderSetSummaryVersionRangeRule: WeightedOrderSetSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedOrderSetSummary) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedOrderSetSummaryLabelLengthRule: WeightedOrderSetSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedOrderSetSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted order set summary.
    final class WeightedOrderSetSummaryValidator {
        var rules: [any WeightedOrderSetSummaryRule]

        init(rules: [any WeightedOrderSetSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedOrderSetSummary) -> [String] {
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

        func requireValid(_ item: WeightedOrderSetSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedOrderSetSummary]) -> [String: [String]] {
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

    static func defaultWeightedOrderSetSummaryValidator() -> WeightedOrderSetSummaryValidator {
        return WeightedOrderSetSummaryValidator(
            rules: [
                WeightedOrderSetSummaryRequiredSourceRule(message: "weighted order set summary needs an entry"),
                WeightedOrderSetSummaryCodeLengthRule(maxLength: 120),
                WeightedOrderSetSummaryVersionRangeRule(min: 80, max: 255),
                WeightedOrderSetSummaryLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
