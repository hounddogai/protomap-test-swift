import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a scheduled statement profile must pass. Check returns its problems, or none.
    protocol ScheduledStatementProfileRule {
        func check(_ item: ScheduledStatementProfile) -> [String]
    }

    final class ScheduledStatementProfileLabelLengthRule: ScheduledStatementProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledStatementProfile) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledStatementProfileEndsAtRangeRule: ScheduledStatementProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledStatementProfile) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledStatementProfileRequiredChannelRule: ScheduledStatementProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledStatementProfile) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledStatementProfileAllowedCodeRule: ScheduledStatementProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledStatementProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class ScheduledStatementProfileRequiredCodeRule: ScheduledStatementProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledStatementProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledStatementProfileCeilingRangeRule: ScheduledStatementProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledStatementProfile) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled statement profile.
    final class ScheduledStatementProfileValidator {
        var rules: [any ScheduledStatementProfileRule]

        init(rules: [any ScheduledStatementProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledStatementProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledStatementProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledStatementProfile]) -> [String: [String]] {
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

    static func defaultScheduledStatementProfileValidator() -> ScheduledStatementProfileValidator {
        return ScheduledStatementProfileValidator(
            rules: [
                ScheduledStatementProfileLabelLengthRule(maxLength: 86400),
                ScheduledStatementProfileEndsAtRangeRule(min: 16, max: 255),
                ScheduledStatementProfileRequiredChannelRule(message: "scheduled statement profile needs this field"),
                ScheduledStatementProfileAllowedCodeRule(allowed: ["adaptive"]),
                ScheduledStatementProfileRequiredCodeRule(message: "scheduled statement profile needs a value"),
                ScheduledStatementProfileCeilingRangeRule(min: 4.8, max: 3047.7),
            ]
        )
    }
}
