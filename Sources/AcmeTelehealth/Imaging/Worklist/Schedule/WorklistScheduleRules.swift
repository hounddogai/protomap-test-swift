import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist schedule must pass. Check returns its problems, or none.
    protocol WorklistScheduleRule {
        func check(_ item: WorklistSchedule) -> [String]
    }

    final class WorklistScheduleRequiredLabelRule: WorklistScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistSchedule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistScheduleAllowedLabelRule: WorklistScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WorklistSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    final class WorklistScheduleApprovedGuardRule: WorklistScheduleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: WorklistSchedule) -> [String] {
            if item.approved && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class WorklistScheduleMaximumRangeRule: WorklistScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistSchedule) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a worklist schedule.
    final class WorklistScheduleValidator {
        var rules: [any WorklistScheduleRule]

        init(rules: [any WorklistScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistSchedule]) -> [String: [String]] {
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

    static func defaultWorklistScheduleValidator() -> WorklistScheduleValidator {
        return WorklistScheduleValidator(
            rules: [
                WorklistScheduleRequiredLabelRule(message: "worklist schedule needs this field"),
                WorklistScheduleAllowedLabelRule(allowed: ["adaptive"]),
                WorklistScheduleApprovedGuardRule(limit: 0.8),
                WorklistScheduleMaximumRangeRule(min: 5.2, max: 1124.2),
            ]
        )
    }
}
