import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement mapping must pass. Check returns its problems, or none.
    protocol StatementMappingRule {
        func check(_ item: StatementMapping) -> [String]
    }

    final class StatementMappingCeilingRangeRule: StatementMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementMapping) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementMappingSpecialtyLengthRule: StatementMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementMapping) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementMappingProcedureCodeLengthRule: StatementMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementMapping) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementMappingTitleLengthRule: StatementMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementMapping) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementMappingRequiredSpecialtyRule: StatementMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementMapping) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a statement mapping.
    final class StatementMappingValidator {
        var rules: [any StatementMappingRule]

        init(rules: [any StatementMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementMapping) -> [String] {
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

        func requireValid(_ item: StatementMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementMapping]) -> [String: [String]] {
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

    static func defaultStatementMappingValidator() -> StatementMappingValidator {
        return StatementMappingValidator(
            rules: [
                StatementMappingCeilingRangeRule(min: 4.2, max: 144.9),
                StatementMappingSpecialtyLengthRule(maxLength: 255),
                StatementMappingProcedureCodeLengthRule(maxLength: 120),
                StatementMappingTitleLengthRule(maxLength: 3600),
                StatementMappingRequiredSpecialtyRule(message: "statement mapping needs an entry"),
            ]
        )
    }
}
