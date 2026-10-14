import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default specimen plan must pass. Check returns its problems, or none.
    protocol DefaultSpecimenPlanRule {
        func check(_ item: DefaultSpecimenPlan) -> [String]
    }

    final class DefaultSpecimenPlanRequiredTitleRule: DefaultSpecimenPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSpecimenPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSpecimenPlanRequiredCodeRule: DefaultSpecimenPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSpecimenPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSpecimenPlanCodeLengthRule: DefaultSpecimenPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSpecimenPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultSpecimenPlanCodePrefixRule: DefaultSpecimenPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultSpecimenPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultSpecimenPlanRequiredUnitRule: DefaultSpecimenPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultSpecimenPlan) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultSpecimenPlanMarginRangeRule: DefaultSpecimenPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultSpecimenPlan) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a default specimen plan.
    final class DefaultSpecimenPlanValidator {
        var rules: [any DefaultSpecimenPlanRule]

        init(rules: [any DefaultSpecimenPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultSpecimenPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultSpecimenPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultSpecimenPlan]) -> [String: [String]] {
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

    static func defaultDefaultSpecimenPlanValidator() -> DefaultSpecimenPlanValidator {
        return DefaultSpecimenPlanValidator(
            rules: [
                DefaultSpecimenPlanRequiredTitleRule(message: "default specimen plan needs an entry"),
                DefaultSpecimenPlanRequiredCodeRule(message: "default specimen plan needs an entry"),
                DefaultSpecimenPlanCodeLengthRule(maxLength: 32),
                DefaultSpecimenPlanCodePrefixRule(prefix: "ACM"),
                DefaultSpecimenPlanRequiredUnitRule(message: "default specimen plan needs a value"),
                DefaultSpecimenPlanMarginRangeRule(min: 4.3, max: 4266.4),
            ]
        )
    }
}
