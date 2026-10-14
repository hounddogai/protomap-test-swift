import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program plan must pass. Check returns its problems, or none.
    protocol ProgramPlanRule {
        func check(_ item: ProgramPlan) -> [String]
    }

    final class ProgramPlanNameLengthRule: ProgramPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramPlan) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramPlanGraceDaysRangeRule: ProgramPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramPlan) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramPlanRequiredCodeRule: ProgramPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a program plan.
    final class ProgramPlanValidator {
        var rules: [any ProgramPlanRule]

        init(rules: [any ProgramPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramPlan]) -> [String: [String]] {
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

    static func defaultProgramPlanValidator() -> ProgramPlanValidator {
        return ProgramPlanValidator(
            rules: [
                ProgramPlanNameLengthRule(maxLength: 3600),
                ProgramPlanGraceDaysRangeRule(min: 32, max: 64),
                ProgramPlanRequiredCodeRule(message: "program plan needs this field"),
            ]
        )
    }
}
