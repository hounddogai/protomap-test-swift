import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation exception must pass. Check returns its problems, or none.
    protocol IsolationExceptionRule {
        func check(_ item: IsolationException) -> [String]
    }

    final class IsolationExceptionRequiredProcedureCodeRule: IsolationExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationException) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationExceptionCodeLengthRule: IsolationExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationExceptionBudgetRangeRule: IsolationExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationException) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class IsolationExceptionRetriesRangeRule: IsolationExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationException) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation exception.
    final class IsolationExceptionValidator {
        var rules: [any IsolationExceptionRule]

        init(rules: [any IsolationExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationException) -> [String] {
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

        func requireValid(_ item: IsolationException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationException]) -> [String: [String]] {
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

    static func defaultIsolationExceptionValidator() -> IsolationExceptionValidator {
        return IsolationExceptionValidator(
            rules: [
                IsolationExceptionRequiredProcedureCodeRule(message: "isolation exception needs a value"),
                IsolationExceptionCodeLengthRule(maxLength: 64),
                IsolationExceptionBudgetRangeRule(min: 1.1, max: 4439.5),
                IsolationExceptionRetriesRangeRule(min: 64, max: 3600),
            ]
        )
    }
}
