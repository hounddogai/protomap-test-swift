import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task segment must pass. Check returns its problems, or none.
    protocol TaskSegmentRule {
        func check(_ item: TaskSegment) -> [String]
    }

    final class TaskSegmentRequiredNameRule: TaskSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskSegment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskSegmentNameLengthRule: TaskSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskSegment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskSegmentFacilityLengthRule: TaskSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskSegment) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskSegmentMaximumRangeRule: TaskSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskSegment) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TaskSegmentRequiredCodeRule: TaskSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskSegmentAllowedFacilityRule: TaskSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TaskSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a task segment.
    final class TaskSegmentValidator {
        var rules: [any TaskSegmentRule]

        init(rules: [any TaskSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TaskSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskSegment]) -> [String: [String]] {
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

    static func defaultTaskSegmentValidator() -> TaskSegmentValidator {
        return TaskSegmentValidator(
            rules: [
                TaskSegmentRequiredNameRule(message: "task segment needs a value"),
                TaskSegmentNameLengthRule(maxLength: 255),
                TaskSegmentFacilityLengthRule(maxLength: 1000),
                TaskSegmentMaximumRangeRule(min: 5.4, max: 1894.5),
                TaskSegmentRequiredCodeRule(message: "task segment needs an entry"),
                TaskSegmentAllowedFacilityRule(allowed: ["adaptive", "pending", "legacy"]),
            ]
        )
    }
}
