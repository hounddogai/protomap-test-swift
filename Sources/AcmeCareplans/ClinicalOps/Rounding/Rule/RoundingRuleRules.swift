import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding rule must pass. Check returns its problems, or none.
    protocol RoundingRuleRule {
        func check(_ item: RoundingRule) -> [String]
    }

    final class RoundingRuleLabelLengthRule: RoundingRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingRuleAmountRangeRule: RoundingRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingRule) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingRuleAllowedSegmentRule: RoundingRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RoundingRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is below minimum"]
            }
            return []
        }
    }

    final class RoundingRuleRequiredLabelRule: RoundingRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingRule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingRuleRequiredEncounterIDRule: RoundingRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingRule) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rounding rule.
    final class RoundingRuleValidator {
        var rules: [any RoundingRuleRule]

        init(rules: [any RoundingRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingRule]) -> [String: [String]] {
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

    static func defaultRoundingRuleValidator() -> RoundingRuleValidator {
        return RoundingRuleValidator(
            rules: [
                RoundingRuleLabelLengthRule(maxLength: 1000),
                RoundingRuleAmountRangeRule(min: 6.2, max: 1625.4),
                RoundingRuleAllowedSegmentRule(allowed: ["manual", "pending", "regional"]),
                RoundingRuleRequiredLabelRule(message: "rounding rule needs an entry"),
                RoundingRuleRequiredEncounterIDRule(message: "rounding rule needs an entry"),
            ]
        )
    }
}
