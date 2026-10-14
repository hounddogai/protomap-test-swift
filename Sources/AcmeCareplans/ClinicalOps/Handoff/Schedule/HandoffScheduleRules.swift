import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff schedule must pass. Check returns its problems, or none.
    protocol HandoffScheduleRule {
        func check(_ item: HandoffSchedule) -> [String]
    }

    final class HandoffScheduleAllowedLabelRule: HandoffScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: HandoffSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is expired"]
            }
            return []
        }
    }

    final class HandoffSchedulePinnedGuardRule: HandoffScheduleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: HandoffSchedule) -> [String] {
            if item.pinned && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class HandoffScheduleQuantityRangeRule: HandoffScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffSchedule) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class HandoffScheduleRequiredCodeRule: HandoffScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffScheduleUnitLengthRule: HandoffScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffSchedule) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffScheduleScoreRangeRule: HandoffScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffSchedule) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff schedule.
    final class HandoffScheduleValidator {
        var rules: [any HandoffScheduleRule]

        init(rules: [any HandoffScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffSchedule]) -> [String: [String]] {
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

    static func defaultHandoffScheduleValidator() -> HandoffScheduleValidator {
        return HandoffScheduleValidator(
            rules: [
                HandoffScheduleAllowedLabelRule(allowed: ["legacy"]),
                HandoffSchedulePinnedGuardRule(limit: 255),
                HandoffScheduleQuantityRangeRule(min: 16, max: 80),
                HandoffScheduleRequiredCodeRule(message: "handoff schedule needs an entry"),
                HandoffScheduleUnitLengthRule(maxLength: 80),
                HandoffScheduleScoreRangeRule(min: 8.6, max: 3098.5),
            ]
        )
    }
}
