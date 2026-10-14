import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled cleaning assignment must pass. Check returns its problems, or none.
    protocol ScheduledCleaningAssignmentRule {
        func check(_ item: ScheduledCleaningAssignment) -> [String]
    }

    final class ScheduledCleaningAssignmentDosageMgRangeRule: ScheduledCleaningAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCleaningAssignment) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledCleaningAssignmentRequiredCodeRule: ScheduledCleaningAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCleaningAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCleaningAssignmentTagsLimitRule: ScheduledCleaningAssignmentRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ScheduledCleaningAssignment) -> [String] {
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

    /// Runs every rule of a scheduled cleaning assignment.
    final class ScheduledCleaningAssignmentValidator {
        var rules: [any ScheduledCleaningAssignmentRule]

        init(rules: [any ScheduledCleaningAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCleaningAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCleaningAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCleaningAssignment]) -> [String: [String]] {
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

    static func defaultScheduledCleaningAssignmentValidator() -> ScheduledCleaningAssignmentValidator {
        return ScheduledCleaningAssignmentValidator(
            rules: [
                ScheduledCleaningAssignmentDosageMgRangeRule(min: 1.8, max: 1208.1),
                ScheduledCleaningAssignmentRequiredCodeRule(message: "scheduled cleaning assignment needs a value"),
                ScheduledCleaningAssignmentTagsLimitRule(maxCount: 255, banned: ["batched", "batched"]),
            ]
        )
    }
}
