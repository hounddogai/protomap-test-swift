import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime budget must pass. Check returns its problems, or none.
    protocol OvertimeBudgetRule {
        func check(_ item: OvertimeBudget) -> [String]
    }

    final class OvertimeBudgetCodeLengthRule: OvertimeBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeBudgetFloorValueRangeRule: OvertimeBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeBudget) -> [String] {
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

    final class OvertimeBudgetClinicianIDLengthRule: OvertimeBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeBudget) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeBudgetRequiredNameRule: OvertimeBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime budget.
    final class OvertimeBudgetValidator {
        var rules: [any OvertimeBudgetRule]

        init(rules: [any OvertimeBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeBudget) -> [String] {
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

        func requireValid(_ item: OvertimeBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeBudget]) -> [String: [String]] {
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

    static func defaultOvertimeBudgetValidator() -> OvertimeBudgetValidator {
        return OvertimeBudgetValidator(
            rules: [
                OvertimeBudgetCodeLengthRule(maxLength: 32),
                OvertimeBudgetFloorValueRangeRule(min: 3.1, max: 3080.0),
                OvertimeBudgetClinicianIDLengthRule(maxLength: 255),
                OvertimeBudgetRequiredNameRule(message: "overtime budget needs this field"),
            ]
        )
    }
}
