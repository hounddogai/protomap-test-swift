import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled panel group must pass. Check returns its problems, or none.
    protocol ScheduledPanelGroupRule {
        func check(_ item: ScheduledPanelGroup) -> [String]
    }

    final class ScheduledPanelGroupCostRangeRule: ScheduledPanelGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledPanelGroup) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledPanelGroupRequiredWardRule: ScheduledPanelGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPanelGroup) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledPanelGroupAllowedTitleRule: ScheduledPanelGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledPanelGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is expired"]
            }
            return []
        }
    }

    final class ScheduledPanelGroupRequiredTitleRule: ScheduledPanelGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPanelGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledPanelGroupRequiredCodeRule: ScheduledPanelGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPanelGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledPanelGroupTitleLengthRule: ScheduledPanelGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledPanelGroup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled panel group.
    final class ScheduledPanelGroupValidator {
        var rules: [any ScheduledPanelGroupRule]

        init(rules: [any ScheduledPanelGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledPanelGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledPanelGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledPanelGroup]) -> [String: [String]] {
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

    static func defaultScheduledPanelGroupValidator() -> ScheduledPanelGroupValidator {
        return ScheduledPanelGroupValidator(
            rules: [
                ScheduledPanelGroupCostRangeRule(min: 7.0, max: 1395.5),
                ScheduledPanelGroupRequiredWardRule(message: "scheduled panel group needs this field"),
                ScheduledPanelGroupAllowedTitleRule(allowed: ["capped", "adaptive"]),
                ScheduledPanelGroupRequiredTitleRule(message: "scheduled panel group needs an entry"),
                ScheduledPanelGroupRequiredCodeRule(message: "scheduled panel group needs this field"),
                ScheduledPanelGroupTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
