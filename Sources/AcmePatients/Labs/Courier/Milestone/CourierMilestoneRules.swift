import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier milestone must pass. Check returns its problems, or none.
    protocol CourierMilestoneRule {
        func check(_ item: CourierMilestone) -> [String]
    }

    final class CourierMilestoneChannelLengthRule: CourierMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierMilestone) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierMilestoneAttemptsRangeRule: CourierMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierMilestone) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CourierMilestoneRequiredCodeRule: CourierMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierMilestoneWindowDaysRangeRule: CourierMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierMilestone) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CourierMilestoneAllowedLabelRule: CourierMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a courier milestone.
    final class CourierMilestoneValidator {
        var rules: [any CourierMilestoneRule]

        init(rules: [any CourierMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierMilestone]) -> [String: [String]] {
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

    static func defaultCourierMilestoneValidator() -> CourierMilestoneValidator {
        return CourierMilestoneValidator(
            rules: [
                CourierMilestoneChannelLengthRule(maxLength: 86400),
                CourierMilestoneAttemptsRangeRule(min: 255, max: 86400),
                CourierMilestoneRequiredCodeRule(message: "courier milestone needs a value"),
                CourierMilestoneWindowDaysRangeRule(min: 80, max: 120),
                CourierMilestoneAllowedLabelRule(allowed: ["strict", "rolling", "tiered"]),
            ]
        )
    }
}
