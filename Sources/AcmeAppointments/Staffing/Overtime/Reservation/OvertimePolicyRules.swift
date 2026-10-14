import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime policy must pass. Check returns its problems, or none.
    protocol OvertimePolicyRule {
        func check(_ item: OvertimePolicy) -> [String]
    }

    final class OvertimePolicyRateRangeRule: OvertimePolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimePolicy) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OvertimePolicyLimitRangeRule: OvertimePolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimePolicy) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OvertimePolicyProcedureCodeLengthRule: OvertimePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimePolicy) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime policy.
    final class OvertimePolicyValidator {
        var rules: [any OvertimePolicyRule]

        init(rules: [any OvertimePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimePolicy) -> [String] {
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

        func requireValid(_ item: OvertimePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimePolicy]) -> [String: [String]] {
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

    static func defaultOvertimePolicyValidator() -> OvertimePolicyValidator {
        return OvertimePolicyValidator(
            rules: [
                OvertimePolicyRateRangeRule(min: 6.0, max: 3623.9),
                OvertimePolicyLimitRangeRule(min: 16, max: 80),
                OvertimePolicyProcedureCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
