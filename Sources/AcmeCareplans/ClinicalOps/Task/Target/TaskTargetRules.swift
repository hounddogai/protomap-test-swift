import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task target must pass. Check returns its problems, or none.
    protocol TaskTargetRule {
        func check(_ item: TaskTarget) -> [String]
    }

    final class TaskTargetCodePrefixRule: TaskTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskTargetTagsLimitRule: TaskTargetRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: TaskTarget) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class TaskTargetFloorValueRangeRule: TaskTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskTarget) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskTargetRequiredLabelRule: TaskTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a task target.
    final class TaskTargetValidator {
        var rules: [any TaskTargetRule]

        init(rules: [any TaskTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskTarget) -> [String] {
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

        func requireValid(_ item: TaskTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskTarget]) -> [String: [String]] {
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

    static func defaultTaskTargetValidator() -> TaskTargetValidator {
        return TaskTargetValidator(
            rules: [
                TaskTargetCodePrefixRule(prefix: "OPS"),
                TaskTargetTagsLimitRule(maxCount: 3600, banned: ["adaptive", "global", "weighted"]),
                TaskTargetFloorValueRangeRule(min: 7.3, max: 610.1),
                TaskTargetRequiredLabelRule(message: "task target needs a value"),
            ]
        )
    }
}
