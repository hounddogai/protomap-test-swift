import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a tiered cleaning rule must pass. Check returns its problems, or none.
    protocol TieredCleaningRuleRule {
        func check(_ item: TieredCleaningRule) -> [String]
    }

    final class TieredCleaningRuleDiscountRangeRule: TieredCleaningRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCleaningRule) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredCleaningRuleRequiredCodeRule: TieredCleaningRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCleaningRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredCleaningRuleCodePrefixRule: TieredCleaningRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredCleaningRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered cleaning rule.
    final class TieredCleaningRuleValidator {
        var rules: [any TieredCleaningRuleRule]

        init(rules: [any TieredCleaningRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCleaningRule) -> [String] {
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

        func requireValid(_ item: TieredCleaningRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCleaningRule]) -> [String: [String]] {
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

    static func defaultTieredCleaningRuleValidator() -> TieredCleaningRuleValidator {
        return TieredCleaningRuleValidator(
            rules: [
                TieredCleaningRuleDiscountRangeRule(min: 8.9, max: 3790.0),
                TieredCleaningRuleRequiredCodeRule(message: "tiered cleaning rule needs an entry"),
                TieredCleaningRuleCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
