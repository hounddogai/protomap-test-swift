import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default float pool assignment must pass. Check returns its problems, or none.
    protocol DefaultFloatPoolAssignmentRule {
        func check(_ item: DefaultFloatPoolAssignment) -> [String]
    }

    final class DefaultFloatPoolAssignmentCostRangeRule: DefaultFloatPoolAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultFloatPoolAssignment) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultFloatPoolAssignmentRequiredSourceRule: DefaultFloatPoolAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultFloatPoolAssignment) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultFloatPoolAssignmentCodeLengthRule: DefaultFloatPoolAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultFloatPoolAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultFloatPoolAssignmentRequiredCodeRule: DefaultFloatPoolAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultFloatPoolAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default float pool assignment.
    final class DefaultFloatPoolAssignmentValidator {
        var rules: [any DefaultFloatPoolAssignmentRule]

        init(rules: [any DefaultFloatPoolAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultFloatPoolAssignment) -> [String] {
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

        func requireValid(_ item: DefaultFloatPoolAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultFloatPoolAssignment]) -> [String: [String]] {
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

    static func defaultDefaultFloatPoolAssignmentValidator() -> DefaultFloatPoolAssignmentValidator {
        return DefaultFloatPoolAssignmentValidator(
            rules: [
                DefaultFloatPoolAssignmentCostRangeRule(min: 0.1, max: 4903.5),
                DefaultFloatPoolAssignmentRequiredSourceRule(message: "default float pool assignment needs a value"),
                DefaultFloatPoolAssignmentCodeLengthRule(maxLength: 3600),
                DefaultFloatPoolAssignmentRequiredCodeRule(message: "default float pool assignment needs a value"),
            ]
        )
    }
}
