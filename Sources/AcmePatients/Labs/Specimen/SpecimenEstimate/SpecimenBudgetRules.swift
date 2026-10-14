import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen budget must pass. Check returns its problems, or none.
    protocol SpecimenBudgetRule {
        func check(_ item: SpecimenBudget) -> [String]
    }

    final class SpecimenBudgetFloorValueRangeRule: SpecimenBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenBudget) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenBudgetRequiredLabelRule: SpecimenBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenBudget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenBudgetCodePrefixRule: SpecimenBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SpecimenBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen budget.
    final class SpecimenBudgetValidator {
        var rules: [any SpecimenBudgetRule]

        init(rules: [any SpecimenBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenBudget) -> [String] {
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

        func requireValid(_ item: SpecimenBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenBudget]) -> [String: [String]] {
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

    static func defaultSpecimenBudgetValidator() -> SpecimenBudgetValidator {
        return SpecimenBudgetValidator(
            rules: [
                SpecimenBudgetFloorValueRangeRule(min: 4.4, max: 299.8),
                SpecimenBudgetRequiredLabelRule(message: "specimen budget needs this field"),
                SpecimenBudgetCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
