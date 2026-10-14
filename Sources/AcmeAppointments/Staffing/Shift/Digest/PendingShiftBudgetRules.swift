import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending shift budget must pass. Check returns its problems, or none.
    protocol PendingShiftBudgetRule {
        func check(_ item: PendingShiftBudget) -> [String]
    }

    final class PendingShiftBudgetWindowDaysRangeRule: PendingShiftBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingShiftBudget) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingShiftBudgetCodeLengthRule: PendingShiftBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingShiftBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingShiftBudgetRequiredCodeRule: PendingShiftBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingShiftBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingShiftBudgetStartsAtRangeRule: PendingShiftBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingShiftBudget) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingShiftBudgetRequiredClinicianIDRule: PendingShiftBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingShiftBudget) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingShiftBudgetRequiredLocaleRule: PendingShiftBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingShiftBudget) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending shift budget.
    final class PendingShiftBudgetValidator {
        var rules: [any PendingShiftBudgetRule]

        init(rules: [any PendingShiftBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingShiftBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingShiftBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingShiftBudget]) -> [String: [String]] {
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

    static func defaultPendingShiftBudgetValidator() -> PendingShiftBudgetValidator {
        return PendingShiftBudgetValidator(
            rules: [
                PendingShiftBudgetWindowDaysRangeRule(min: 1000, max: 86400),
                PendingShiftBudgetCodeLengthRule(maxLength: 1000),
                PendingShiftBudgetRequiredCodeRule(message: "pending shift budget needs an entry"),
                PendingShiftBudgetStartsAtRangeRule(min: 16, max: 86400),
                PendingShiftBudgetRequiredClinicianIDRule(message: "pending shift budget needs this field"),
                PendingShiftBudgetRequiredLocaleRule(message: "pending shift budget needs a value"),
            ]
        )
    }
}
