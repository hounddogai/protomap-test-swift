import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a weighted order set rule must pass. Check returns its problems, or none.
    protocol WeightedOrderSetRuleRule {
        func check(_ item: WeightedOrderSetRule) -> [String]
    }

    final class WeightedOrderSetRuleSpecialtyLengthRule: WeightedOrderSetRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedOrderSetRule) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedOrderSetRuleRequiredCodeRule: WeightedOrderSetRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedOrderSetRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedOrderSetRuleNameLengthRule: WeightedOrderSetRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedOrderSetRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedOrderSetRuleCodePrefixRule: WeightedOrderSetRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedOrderSetRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedOrderSetRuleRequiredNameRule: WeightedOrderSetRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedOrderSetRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted order set rule.
    final class WeightedOrderSetRuleValidator {
        var rules: [any WeightedOrderSetRuleRule]

        init(rules: [any WeightedOrderSetRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedOrderSetRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedOrderSetRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedOrderSetRule]) -> [String: [String]] {
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

    static func defaultWeightedOrderSetRuleValidator() -> WeightedOrderSetRuleValidator {
        return WeightedOrderSetRuleValidator(
            rules: [
                WeightedOrderSetRuleSpecialtyLengthRule(maxLength: 86400),
                WeightedOrderSetRuleRequiredCodeRule(message: "weighted order set rule needs a value"),
                WeightedOrderSetRuleNameLengthRule(maxLength: 80),
                WeightedOrderSetRuleCodePrefixRule(prefix: "OPS"),
                WeightedOrderSetRuleRequiredNameRule(message: "weighted order set rule needs an entry"),
            ]
        )
    }
}
