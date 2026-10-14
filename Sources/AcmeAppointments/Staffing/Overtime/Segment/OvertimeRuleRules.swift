import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime rule must pass. Check returns its problems, or none.
    protocol OvertimeRuleRule {
        func check(_ item: OvertimeRule) -> [String]
    }

    final class OvertimeRulePayerLengthRule: OvertimeRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeRule) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeRuleCodeLengthRule: OvertimeRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeRuleRequiredProcedureCodeRule: OvertimeRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeRule) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeRuleMaximumRangeRule: OvertimeRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeRule) -> [String] {
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

    final class OvertimeRuleThresholdRangeRule: OvertimeRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeRule) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime rule.
    final class OvertimeRuleValidator {
        var rules: [any OvertimeRuleRule]

        init(rules: [any OvertimeRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeRule) -> [String] {
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

        func requireValid(_ item: OvertimeRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeRule]) -> [String: [String]] {
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

    static func defaultOvertimeRuleValidator() -> OvertimeRuleValidator {
        return OvertimeRuleValidator(
            rules: [
                OvertimeRulePayerLengthRule(maxLength: 120),
                OvertimeRuleCodeLengthRule(maxLength: 86400),
                OvertimeRuleRequiredProcedureCodeRule(message: "overtime rule needs an entry"),
                OvertimeRuleMaximumRangeRule(min: 3.4, max: 3015.9),
                OvertimeRuleThresholdRangeRule(min: 2.6, max: 3769.1),
            ]
        )
    }
}
