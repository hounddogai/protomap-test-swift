import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure mapping must pass. Check returns its problems, or none.
    protocol ClosureMappingRule {
        func check(_ item: ClosureMapping) -> [String]
    }

    final class ClosureMappingRequiredLabelRule: ClosureMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureMapping) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureMappingAllowedLocaleRule: ClosureMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClosureMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is blocked"]
            }
            return []
        }
    }

    final class ClosureMappingQuantityRangeRule: ClosureMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureMapping) -> [String] {
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

    /// Runs every rule of a closure mapping.
    final class ClosureMappingValidator {
        var rules: [any ClosureMappingRule]

        init(rules: [any ClosureMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureMapping]) -> [String: [String]] {
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

    static func defaultClosureMappingValidator() -> ClosureMappingValidator {
        return ClosureMappingValidator(
            rules: [
                ClosureMappingRequiredLabelRule(message: "closure mapping needs an entry"),
                ClosureMappingAllowedLocaleRule(allowed: []),
                ClosureMappingQuantityRangeRule(min: 32, max: 120),
            ]
        )
    }
}
