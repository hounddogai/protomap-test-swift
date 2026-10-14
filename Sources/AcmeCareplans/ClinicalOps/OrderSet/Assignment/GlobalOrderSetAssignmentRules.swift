import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global order set assignment must pass. Check returns its problems, or none.
    protocol GlobalOrderSetAssignmentRule {
        func check(_ item: GlobalOrderSetAssignment) -> [String]
    }

    final class GlobalOrderSetAssignmentRequiredTimezoneRule: GlobalOrderSetAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalOrderSetAssignment) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalOrderSetAssignmentEndsAtRangeRule: GlobalOrderSetAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalOrderSetAssignment) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalOrderSetAssignmentRequiredNotesRule: GlobalOrderSetAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalOrderSetAssignment) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalOrderSetAssignmentWindowRule: GlobalOrderSetAssignmentRule {
        var maxSpan: Int

        init(maxSpan: Int) {
            self.maxSpan = maxSpan
        }

        func check(_ item: GlobalOrderSetAssignment) -> [String] {
            if item.startsAt > item.endsAt {
                return ["starts at is after ends at"]
            }
            if maxSpan > 0 && (item.endsAt - item.startsAt > maxSpan) {
                return ["spans more than \(maxSpan) seconds"]
            }
            return []
        }
    }

    /// Runs every rule of a global order set assignment.
    final class GlobalOrderSetAssignmentValidator {
        var rules: [any GlobalOrderSetAssignmentRule]

        init(rules: [any GlobalOrderSetAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalOrderSetAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalOrderSetAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalOrderSetAssignment]) -> [String: [String]] {
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

    static func defaultGlobalOrderSetAssignmentValidator() -> GlobalOrderSetAssignmentValidator {
        return GlobalOrderSetAssignmentValidator(
            rules: [
                GlobalOrderSetAssignmentRequiredTimezoneRule(message: "global order set assignment needs a value"),
                GlobalOrderSetAssignmentEndsAtRangeRule(min: 120, max: 86400),
                GlobalOrderSetAssignmentRequiredNotesRule(message: "global order set assignment needs a value"),
                GlobalOrderSetAssignmentWindowRule(maxSpan: 80),
            ]
        )
    }
}
