import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled panel score must pass. Check returns its problems, or none.
    protocol ScheduledPanelScoreRule {
        func check(_ item: ScheduledPanelScore) -> [String]
    }

    final class ScheduledPanelScoreRequiredWardRule: ScheduledPanelScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPanelScore) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledPanelScoreCostRangeRule: ScheduledPanelScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledPanelScore) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledPanelScoreExternalRefLengthRule: ScheduledPanelScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledPanelScore) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledPanelScoreAllowedNameRule: ScheduledPanelScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledPanelScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    final class ScheduledPanelScoreCapacityRangeRule: ScheduledPanelScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledPanelScore) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledPanelScoreMaximumRangeRule: ScheduledPanelScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledPanelScore) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled panel score.
    final class ScheduledPanelScoreValidator {
        var rules: [any ScheduledPanelScoreRule]

        init(rules: [any ScheduledPanelScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledPanelScore) -> [String] {
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

        func requireValid(_ item: ScheduledPanelScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledPanelScore]) -> [String: [String]] {
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

    static func defaultScheduledPanelScoreValidator() -> ScheduledPanelScoreValidator {
        return ScheduledPanelScoreValidator(
            rules: [
                ScheduledPanelScoreRequiredWardRule(message: "scheduled panel score needs a value"),
                ScheduledPanelScoreCostRangeRule(min: 4.5, max: 967.4),
                ScheduledPanelScoreExternalRefLengthRule(maxLength: 1000),
                ScheduledPanelScoreAllowedNameRule(allowed: ["strict"]),
                ScheduledPanelScoreCapacityRangeRule(min: 80, max: 120),
                ScheduledPanelScoreMaximumRangeRule(min: 9.1, max: 4740.1),
            ]
        )
    }
}
