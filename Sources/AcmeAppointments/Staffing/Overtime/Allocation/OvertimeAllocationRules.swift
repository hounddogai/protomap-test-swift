import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime allocation must pass. Check returns its problems, or none.
    protocol OvertimeAllocationRule {
        func check(_ item: OvertimeAllocation) -> [String]
    }

    final class OvertimeAllocationRequiredFacilityRule: OvertimeAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeAllocation) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeAllocationFloorValueRangeRule: OvertimeAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeAllocation) -> [String] {
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

    final class OvertimeAllocationRequiredNameRule: OvertimeAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeAllocation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime allocation.
    final class OvertimeAllocationValidator {
        var rules: [any OvertimeAllocationRule]

        init(rules: [any OvertimeAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeAllocation]) -> [String: [String]] {
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

    static func defaultOvertimeAllocationValidator() -> OvertimeAllocationValidator {
        return OvertimeAllocationValidator(
            rules: [
                OvertimeAllocationRequiredFacilityRule(message: "overtime allocation needs a value"),
                OvertimeAllocationFloorValueRangeRule(min: 8.1, max: 4807.4),
                OvertimeAllocationRequiredNameRule(message: "overtime allocation needs this field"),
            ]
        )
    }
}
