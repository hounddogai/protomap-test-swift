import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen rule must pass. Check returns its problems, or none.
    protocol SpecimenRuleRule {
        func check(_ item: SpecimenRule) -> [String]
    }

    final class SpecimenRuleCostRangeRule: SpecimenRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenRule) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenRuleCodeLengthRule: SpecimenRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenRuleLabelLengthRule: SpecimenRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenRuleCodePrefixRule: SpecimenRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SpecimenRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen rule.
    final class SpecimenRuleValidator {
        var rules: [any SpecimenRuleRule]

        init(rules: [any SpecimenRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenRule) -> [String] {
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

        func requireValid(_ item: SpecimenRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenRule]) -> [String: [String]] {
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

    static func defaultSpecimenRuleValidator() -> SpecimenRuleValidator {
        return SpecimenRuleValidator(
            rules: [
                SpecimenRuleCostRangeRule(min: 1.9, max: 2889.6),
                SpecimenRuleCodeLengthRule(maxLength: 3600),
                SpecimenRuleLabelLengthRule(maxLength: 32),
                SpecimenRuleCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
