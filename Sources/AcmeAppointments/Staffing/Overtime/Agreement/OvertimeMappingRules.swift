import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime mapping must pass. Check returns its problems, or none.
    protocol OvertimeMappingRule {
        func check(_ item: OvertimeMapping) -> [String]
    }

    final class OvertimeMappingCopayRangeRule: OvertimeMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeMapping) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OvertimeMappingRequiredTitleRule: OvertimeMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeMappingRequiredProcedureCodeRule: OvertimeMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeMapping) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime mapping.
    final class OvertimeMappingValidator {
        var rules: [any OvertimeMappingRule]

        init(rules: [any OvertimeMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeMapping) -> [String] {
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

        func requireValid(_ item: OvertimeMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeMapping]) -> [String: [String]] {
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

    static func defaultOvertimeMappingValidator() -> OvertimeMappingValidator {
        return OvertimeMappingValidator(
            rules: [
                OvertimeMappingCopayRangeRule(min: 6.4, max: 4900.6),
                OvertimeMappingRequiredTitleRule(message: "overtime mapping needs this field"),
                OvertimeMappingRequiredProcedureCodeRule(message: "overtime mapping needs a value"),
            ]
        )
    }
}
