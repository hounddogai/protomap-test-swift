import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime plan must pass. Check returns its problems, or none.
    protocol OvertimePlanRule {
        func check(_ item: OvertimePlan) -> [String]
    }

    final class OvertimePlanRequiredPhoneRule: OvertimePlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimePlan) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimePlanCapacityRangeRule: OvertimePlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimePlan) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OvertimePlanCodePrefixRule: OvertimePlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OvertimePlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime plan.
    final class OvertimePlanValidator {
        var rules: [any OvertimePlanRule]

        init(rules: [any OvertimePlanRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimePlan) -> [String] {
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

        func requireValid(_ item: OvertimePlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimePlan]) -> [String: [String]] {
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

    static func defaultOvertimePlanValidator() -> OvertimePlanValidator {
        return OvertimePlanValidator(
            rules: [
                OvertimePlanRequiredPhoneRule(message: "overtime plan needs this field"),
                OvertimePlanCapacityRangeRule(min: 1000, max: 86400),
                OvertimePlanCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
