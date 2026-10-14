import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist group must pass. Check returns its problems, or none.
    protocol WorklistGroupRule {
        func check(_ item: WorklistGroup) -> [String]
    }

    final class WorklistGroupSpecialtyLengthRule: WorklistGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistGroup) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistGroupCodeLengthRule: WorklistGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistGroupRequiredUnitRule: WorklistGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistGroup) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a worklist group.
    final class WorklistGroupValidator {
        var rules: [any WorklistGroupRule]

        init(rules: [any WorklistGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistGroup]) -> [String: [String]] {
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

    static func defaultWorklistGroupValidator() -> WorklistGroupValidator {
        return WorklistGroupValidator(
            rules: [
                WorklistGroupSpecialtyLengthRule(maxLength: 16),
                WorklistGroupCodeLengthRule(maxLength: 3600),
                WorklistGroupRequiredUnitRule(message: "worklist group needs a value"),
            ]
        )
    }
}
