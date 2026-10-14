import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task profile must pass. Check returns its problems, or none.
    protocol TaskProfileRule {
        func check(_ item: TaskProfile) -> [String]
    }

    final class TaskProfileCodeLengthRule: TaskProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskProfileWindowDaysRangeRule: TaskProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskProfile) -> [String] {
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

    final class TaskProfileRequiredAllergyRule: TaskProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskProfile) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskProfileCodePrefixRule: TaskProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskProfileBudgetRangeRule: TaskProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskProfile) -> [String] {
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

    final class TaskProfileAllowedCodeRule: TaskProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a task profile.
    final class TaskProfileValidator {
        var rules: [any TaskProfileRule]

        init(rules: [any TaskProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskProfile]) -> [String: [String]] {
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

    static func defaultTaskProfileValidator() -> TaskProfileValidator {
        return TaskProfileValidator(
            rules: [
                TaskProfileCodeLengthRule(maxLength: 255),
                TaskProfileWindowDaysRangeRule(min: 3600, max: 3600),
                TaskProfileRequiredAllergyRule(message: "task profile needs an entry"),
                TaskProfileCodePrefixRule(prefix: "Q"),
                TaskProfileBudgetRangeRule(min: 7.0, max: 4752.1),
                TaskProfileAllowedCodeRule(allowed: ["global", "strict"]),
            ]
        )
    }
}
