import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a regional overtime plan must pass. Check returns its problems, or none.
    protocol RegionalOvertimePlanRule {
        func check(_ item: RegionalOvertimePlan) -> [String]
    }

    final class RegionalOvertimePlanCodeLengthRule: RegionalOvertimePlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOvertimePlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalOvertimePlanRequiredCodeRule: RegionalOvertimePlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOvertimePlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalOvertimePlanWeightRangeRule: RegionalOvertimePlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalOvertimePlan) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional overtime plan.
    final class RegionalOvertimePlanValidator {
        var rules: [any RegionalOvertimePlanRule]

        init(rules: [any RegionalOvertimePlanRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalOvertimePlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalOvertimePlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalOvertimePlan]) -> [String: [String]] {
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

    static func defaultRegionalOvertimePlanValidator() -> RegionalOvertimePlanValidator {
        return RegionalOvertimePlanValidator(
            rules: [
                RegionalOvertimePlanCodeLengthRule(maxLength: 3600),
                RegionalOvertimePlanRequiredCodeRule(message: "regional overtime plan needs a value"),
                RegionalOvertimePlanWeightRangeRule(min: 5.2, max: 3639.6),
            ]
        )
    }
}
