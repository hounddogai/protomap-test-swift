import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement milestone must pass. Check returns its problems, or none.
    protocol StatementMilestoneRule {
        func check(_ item: StatementMilestone) -> [String]
    }

    final class StatementMilestoneRequiredProcedureCodeRule: StatementMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementMilestone) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementMilestoneCodeLengthRule: StatementMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementMilestoneThresholdRangeRule: StatementMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementMilestone) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementMilestoneProcedureCodeLengthRule: StatementMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementMilestone) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement milestone.
    final class StatementMilestoneValidator {
        var rules: [any StatementMilestoneRule]

        init(rules: [any StatementMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementMilestone) -> [String] {
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

        func requireValid(_ item: StatementMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementMilestone]) -> [String: [String]] {
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

    static func defaultStatementMilestoneValidator() -> StatementMilestoneValidator {
        return StatementMilestoneValidator(
            rules: [
                StatementMilestoneRequiredProcedureCodeRule(message: "statement milestone needs this field"),
                StatementMilestoneCodeLengthRule(maxLength: 1000),
                StatementMilestoneThresholdRangeRule(min: 9.2, max: 1094.6),
                StatementMilestoneProcedureCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
