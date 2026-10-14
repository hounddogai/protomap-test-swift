import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set rule must pass. Check returns its problems, or none.
    protocol OrderSetRuleRule {
        func check(_ item: OrderSetRule) -> [String]
    }

    final class OrderSetRuleNameLengthRule: OrderSetRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetRuleRequiredNameRule: OrderSetRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetRuleTitleLengthRule: OrderSetRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetRuleRequiredCodeRule: OrderSetRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetRuleUpdatedAtRangeRule: OrderSetRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetRule) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetRuleRequiredDiagnosisCodeRule: OrderSetRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetRule) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set rule.
    final class OrderSetRuleValidator {
        var rules: [any OrderSetRuleRule]

        init(rules: [any OrderSetRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetRule]) -> [String: [String]] {
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

    static func defaultOrderSetRuleValidator() -> OrderSetRuleValidator {
        return OrderSetRuleValidator(
            rules: [
                OrderSetRuleNameLengthRule(maxLength: 80),
                OrderSetRuleRequiredNameRule(message: "order set rule needs this field"),
                OrderSetRuleTitleLengthRule(maxLength: 120),
                OrderSetRuleRequiredCodeRule(message: "order set rule needs this field"),
                OrderSetRuleUpdatedAtRangeRule(min: 1000, max: 86400),
                OrderSetRuleRequiredDiagnosisCodeRule(message: "order set rule needs this field"),
            ]
        )
    }
}
