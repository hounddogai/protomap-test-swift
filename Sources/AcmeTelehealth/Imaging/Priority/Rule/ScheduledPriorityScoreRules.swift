import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled priority score must pass. Check returns its problems, or none.
    protocol ScheduledPriorityScoreRule {
        func check(_ item: ScheduledPriorityScore) -> [String]
    }

    final class ScheduledPriorityScoreAllowedLabelRule: ScheduledPriorityScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledPriorityScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class ScheduledPriorityScoreRequiredLabelRule: ScheduledPriorityScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPriorityScore) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledPriorityScoreCodeLengthRule: ScheduledPriorityScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledPriorityScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledPriorityScoreCreatedAtRangeRule: ScheduledPriorityScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledPriorityScore) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledPriorityScoreWeightRangeRule: ScheduledPriorityScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledPriorityScore) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled priority score.
    final class ScheduledPriorityScoreValidator {
        var rules: [any ScheduledPriorityScoreRule]

        init(rules: [any ScheduledPriorityScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledPriorityScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledPriorityScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledPriorityScore]) -> [String: [String]] {
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

    static func defaultScheduledPriorityScoreValidator() -> ScheduledPriorityScoreValidator {
        return ScheduledPriorityScoreValidator(
            rules: [
                ScheduledPriorityScoreAllowedLabelRule(allowed: ["primary", "adaptive"]),
                ScheduledPriorityScoreRequiredLabelRule(message: "scheduled priority score needs this field"),
                ScheduledPriorityScoreCodeLengthRule(maxLength: 120),
                ScheduledPriorityScoreCreatedAtRangeRule(min: 32, max: 1000),
                ScheduledPriorityScoreWeightRangeRule(min: 5.2, max: 2568.3),
            ]
        )
    }
}
