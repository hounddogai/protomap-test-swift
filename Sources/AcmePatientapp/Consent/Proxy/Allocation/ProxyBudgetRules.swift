import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy budget must pass. Check returns its problems, or none.
    protocol ProxyBudgetRule {
        func check(_ item: ProxyBudget) -> [String]
    }

    final class ProxyBudgetMaximumRangeRule: ProxyBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyBudget) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProxyBudgetRequiredCodeRule: ProxyBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyBudgetRequiredNameRule: ProxyBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyBudgetNameLengthRule: ProxyBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyBudget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyBudgetFloorValueRangeRule: ProxyBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyBudget) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy budget.
    final class ProxyBudgetValidator {
        var rules: [any ProxyBudgetRule]

        init(rules: [any ProxyBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyBudget) -> [String] {
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

        func requireValid(_ item: ProxyBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyBudget]) -> [String: [String]] {
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

    static func defaultProxyBudgetValidator() -> ProxyBudgetValidator {
        return ProxyBudgetValidator(
            rules: [
                ProxyBudgetMaximumRangeRule(min: 9.2, max: 4927.1),
                ProxyBudgetRequiredCodeRule(message: "proxy budget needs this field"),
                ProxyBudgetRequiredNameRule(message: "proxy budget needs this field"),
                ProxyBudgetNameLengthRule(maxLength: 1000),
                ProxyBudgetFloorValueRangeRule(min: 7.2, max: 298.8),
            ]
        )
    }
}
