import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling specimen rule must pass. Check returns its problems, or none.
    protocol RollingSpecimenRuleRule {
        func check(_ item: RollingSpecimenRule) -> [String]
    }

    final class RollingSpecimenRulePayerLengthRule: RollingSpecimenRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSpecimenRule) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingSpecimenRuleRequiredCodeRule: RollingSpecimenRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingSpecimenRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingSpecimenRuleAllowedNameRule: RollingSpecimenRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingSpecimenRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is blocked"]
            }
            return []
        }
    }

    final class RollingSpecimenRuleQuantityRangeRule: RollingSpecimenRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingSpecimenRule) -> [String] {
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

    final class RollingSpecimenRuleRequiredNameRule: RollingSpecimenRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingSpecimenRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling specimen rule.
    final class RollingSpecimenRuleValidator {
        var rules: [any RollingSpecimenRuleRule]

        init(rules: [any RollingSpecimenRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingSpecimenRule) -> [String] {
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

        func requireValid(_ item: RollingSpecimenRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingSpecimenRule]) -> [String: [String]] {
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

    static func defaultRollingSpecimenRuleValidator() -> RollingSpecimenRuleValidator {
        return RollingSpecimenRuleValidator(
            rules: [
                RollingSpecimenRulePayerLengthRule(maxLength: 80),
                RollingSpecimenRuleRequiredCodeRule(message: "rolling specimen rule needs a value"),
                RollingSpecimenRuleAllowedNameRule(allowed: ["pending", "seasonal"]),
                RollingSpecimenRuleQuantityRangeRule(min: 3600, max: 86400),
                RollingSpecimenRuleRequiredNameRule(message: "rolling specimen rule needs an entry"),
            ]
        )
    }
}
