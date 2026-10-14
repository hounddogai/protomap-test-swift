import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task preference must pass. Check returns its problems, or none.
    protocol TaskPreferenceRule {
        func check(_ item: TaskPreference) -> [String]
    }

    final class TaskPreferenceRequiredWardRule: TaskPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskPreference) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskPreferenceCodePrefixRule: TaskPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskPreferenceBatchSizeRangeRule: TaskPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskPreference) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskPreferenceAllowedTitleRule: TaskPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is unknown"]
            }
            return []
        }
    }

    final class TaskPreferenceRevisionRangeRule: TaskPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskPreference) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskPreferenceRequiredCodeRule: TaskPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task preference.
    final class TaskPreferenceValidator {
        var rules: [any TaskPreferenceRule]

        init(rules: [any TaskPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskPreference]) -> [String: [String]] {
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

    static func defaultTaskPreferenceValidator() -> TaskPreferenceValidator {
        return TaskPreferenceValidator(
            rules: [
                TaskPreferenceRequiredWardRule(message: "task preference needs this field"),
                TaskPreferenceCodePrefixRule(prefix: "REF"),
                TaskPreferenceBatchSizeRangeRule(min: 64, max: 86400),
                TaskPreferenceAllowedTitleRule(allowed: ["regional", "tiered"]),
                TaskPreferenceRevisionRangeRule(min: 32, max: 120),
                TaskPreferenceRequiredCodeRule(message: "task preference needs this field"),
            ]
        )
    }
}
