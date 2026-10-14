import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted accession rule must pass. Check returns its problems, or none.
    protocol WeightedAccessionRuleRule {
        func check(_ item: WeightedAccessionRule) -> [String]
    }

    final class WeightedAccessionRuleRatioRangeRule: WeightedAccessionRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedAccessionRule) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedAccessionRuleFacilityLengthRule: WeightedAccessionRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAccessionRule) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAccessionRuleRequiredTitleRule: WeightedAccessionRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAccessionRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedAccessionRuleCodeLengthRule: WeightedAccessionRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAccessionRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAccessionRuleRequiredPhoneRule: WeightedAccessionRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAccessionRule) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted accession rule.
    final class WeightedAccessionRuleValidator {
        var rules: [any WeightedAccessionRuleRule]

        init(rules: [any WeightedAccessionRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedAccessionRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedAccessionRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedAccessionRule]) -> [String: [String]] {
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

    static func defaultWeightedAccessionRuleValidator() -> WeightedAccessionRuleValidator {
        return WeightedAccessionRuleValidator(
            rules: [
                WeightedAccessionRuleRatioRangeRule(min: 9.8, max: 2726.5),
                WeightedAccessionRuleFacilityLengthRule(maxLength: 16),
                WeightedAccessionRuleRequiredTitleRule(message: "weighted accession rule needs a value"),
                WeightedAccessionRuleCodeLengthRule(maxLength: 80),
                WeightedAccessionRuleRequiredPhoneRule(message: "weighted accession rule needs this field"),
            ]
        )
    }
}
