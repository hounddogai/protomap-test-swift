import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default interaction schedule must pass. Check returns its problems, or none.
    protocol DefaultInteractionScheduleRule {
        func check(_ item: DefaultInteractionSchedule) -> [String]
    }

    final class DefaultInteractionScheduleCodePrefixRule: DefaultInteractionScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultInteractionSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultInteractionScheduleLabelLengthRule: DefaultInteractionScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultInteractionSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultInteractionSchedulePayerLengthRule: DefaultInteractionScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultInteractionSchedule) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultInteractionScheduleRequiredPayerRule: DefaultInteractionScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultInteractionSchedule) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultInteractionScheduleCapacityRangeRule: DefaultInteractionScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultInteractionSchedule) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultInteractionScheduleVersionRangeRule: DefaultInteractionScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultInteractionSchedule) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default interaction schedule.
    final class DefaultInteractionScheduleValidator {
        var rules: [any DefaultInteractionScheduleRule]

        init(rules: [any DefaultInteractionScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultInteractionSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultInteractionSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultInteractionSchedule]) -> [String: [String]] {
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

    static func defaultDefaultInteractionScheduleValidator() -> DefaultInteractionScheduleValidator {
        return DefaultInteractionScheduleValidator(
            rules: [
                DefaultInteractionScheduleCodePrefixRule(prefix: "OPS"),
                DefaultInteractionScheduleLabelLengthRule(maxLength: 86400),
                DefaultInteractionSchedulePayerLengthRule(maxLength: 80),
                DefaultInteractionScheduleRequiredPayerRule(message: "default interaction schedule needs this field"),
                DefaultInteractionScheduleCapacityRangeRule(min: 86400, max: 86400),
                DefaultInteractionScheduleVersionRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
