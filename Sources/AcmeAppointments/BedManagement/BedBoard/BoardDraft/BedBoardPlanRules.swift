import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board plan must pass. Check returns its problems, or none.
    protocol BedBoardPlanRule {
        func check(_ item: BedBoardPlan) -> [String]
    }

    final class BedBoardPlanRequiredProcedureCodeRule: BedBoardPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardPlan) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardPlanCopayRangeRule: BedBoardPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardPlan) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardPlanCeilingRangeRule: BedBoardPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardPlan) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BedBoardPlanRequiredUnitRule: BedBoardPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardPlan) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a bed board plan.
    final class BedBoardPlanValidator {
        var rules: [any BedBoardPlanRule]

        init(rules: [any BedBoardPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardPlan) -> [String] {
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

        func requireValid(_ item: BedBoardPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardPlan]) -> [String: [String]] {
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

    static func defaultBedBoardPlanValidator() -> BedBoardPlanValidator {
        return BedBoardPlanValidator(
            rules: [
                BedBoardPlanRequiredProcedureCodeRule(message: "bed board plan needs an entry"),
                BedBoardPlanCopayRangeRule(min: 0.2, max: 103.3),
                BedBoardPlanCeilingRangeRule(min: 0.1, max: 1640.7),
                BedBoardPlanRequiredUnitRule(message: "bed board plan needs this field"),
            ]
        )
    }
}
