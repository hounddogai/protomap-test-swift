import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census budget must pass. Check returns its problems, or none.
    protocol CensusBudgetRule {
        func check(_ item: CensusBudget) -> [String]
    }

    final class CensusBudgetUnitLengthRule: CensusBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusBudget) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusBudgetCodePrefixRule: CensusBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusBudgetFloorValueRangeRule: CensusBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusBudget) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a census budget.
    final class CensusBudgetValidator {
        var rules: [any CensusBudgetRule]

        init(rules: [any CensusBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusBudget) -> [String] {
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

        func requireValid(_ item: CensusBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusBudget]) -> [String: [String]] {
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

    static func defaultCensusBudgetValidator() -> CensusBudgetValidator {
        return CensusBudgetValidator(
            rules: [
                CensusBudgetUnitLengthRule(maxLength: 80),
                CensusBudgetCodePrefixRule(prefix: "X"),
                CensusBudgetFloorValueRangeRule(min: 2.7, max: 5001.4),
            ]
        )
    }
}
