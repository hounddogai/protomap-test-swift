import AcmePlatform
import Foundation

extension Labs {
    /// A rule a strict reference range rule must pass. Check returns its problems, or none.
    protocol StrictReferenceRangeRuleRule {
        func check(_ item: StrictReferenceRangeRule) -> [String]
    }

    final class StrictReferenceRangeRuleVersionRangeRule: StrictReferenceRangeRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictReferenceRangeRule) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictReferenceRangeRuleRequiredLabelRule: StrictReferenceRangeRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictReferenceRangeRule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictReferenceRangeRuleQuantityRangeRule: StrictReferenceRangeRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictReferenceRangeRule) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictReferenceRangeRuleRequiredNameRule: StrictReferenceRangeRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictReferenceRangeRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictReferenceRangeRuleEndsAtRangeRule: StrictReferenceRangeRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictReferenceRangeRule) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a strict reference range rule.
    final class StrictReferenceRangeRuleValidator {
        var rules: [any StrictReferenceRangeRuleRule]

        init(rules: [any StrictReferenceRangeRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictReferenceRangeRule) -> [String] {
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

        func requireValid(_ item: StrictReferenceRangeRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictReferenceRangeRule]) -> [String: [String]] {
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

    static func defaultStrictReferenceRangeRuleValidator() -> StrictReferenceRangeRuleValidator {
        return StrictReferenceRangeRuleValidator(
            rules: [
                StrictReferenceRangeRuleVersionRangeRule(min: 80, max: 1000),
                StrictReferenceRangeRuleRequiredLabelRule(message: "strict reference range rule needs a value"),
                StrictReferenceRangeRuleQuantityRangeRule(min: 32, max: 120),
                StrictReferenceRangeRuleRequiredNameRule(message: "strict reference range rule needs a value"),
                StrictReferenceRangeRuleEndsAtRangeRule(min: 32, max: 120),
            ]
        )
    }
}
