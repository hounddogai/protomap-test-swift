import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read budget must pass. Check returns its problems, or none.
    protocol ReadBudgetRule {
        func check(_ item: ReadBudget) -> [String]
    }

    final class ReadBudgetAllowedCodeRule: ReadBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReadBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class ReadBudgetVisitMinutesRangeRule: ReadBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadBudget) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReadBudgetClinicianIDLengthRule: ReadBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadBudget) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadBudgetRequiredCodeRule: ReadBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a read budget.
    final class ReadBudgetValidator {
        var rules: [any ReadBudgetRule]

        init(rules: [any ReadBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadBudget]) -> [String: [String]] {
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

    static func defaultReadBudgetValidator() -> ReadBudgetValidator {
        return ReadBudgetValidator(
            rules: [
                ReadBudgetAllowedCodeRule(allowed: ["seasonal", "pending"]),
                ReadBudgetVisitMinutesRangeRule(min: 120, max: 255),
                ReadBudgetClinicianIDLengthRule(maxLength: 120),
                ReadBudgetRequiredCodeRule(message: "read budget needs this field"),
            ]
        )
    }
}
