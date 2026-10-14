import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set plan must pass. Check returns its problems, or none.
    protocol OrderSetPlanRule {
        func check(_ item: OrderSetPlan) -> [String]
    }

    final class OrderSetPlanCeilingRangeRule: OrderSetPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetPlan) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetPlanRequiredSummaryRule: OrderSetPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetPlan) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetPlanRequiredTitleRule: OrderSetPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetPlanCodePrefixRule: OrderSetPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OrderSetPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OrderSetPlanRequiredCodeRule: OrderSetPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetPlanCodeLengthRule: OrderSetPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set plan.
    final class OrderSetPlanValidator {
        var rules: [any OrderSetPlanRule]

        init(rules: [any OrderSetPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetPlan) -> [String] {
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

        func requireValid(_ item: OrderSetPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetPlan]) -> [String: [String]] {
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

    static func defaultOrderSetPlanValidator() -> OrderSetPlanValidator {
        return OrderSetPlanValidator(
            rules: [
                OrderSetPlanCeilingRangeRule(min: 0.4, max: 415.2),
                OrderSetPlanRequiredSummaryRule(message: "order set plan needs this field"),
                OrderSetPlanRequiredTitleRule(message: "order set plan needs an entry"),
                OrderSetPlanCodePrefixRule(prefix: "OPS"),
                OrderSetPlanRequiredCodeRule(message: "order set plan needs this field"),
                OrderSetPlanCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
