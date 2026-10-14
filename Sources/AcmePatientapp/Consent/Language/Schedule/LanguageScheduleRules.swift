import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language schedule must pass. Check returns its problems, or none.
    protocol LanguageScheduleRule {
        func check(_ item: LanguageSchedule) -> [String]
    }

    final class LanguageScheduleLimitRangeRule: LanguageScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageSchedule) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguageScheduleStartsAtRangeRule: LanguageScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageSchedule) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageScheduleCodeLengthRule: LanguageScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageScheduleCodePrefixRule: LanguageScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LanguageScheduleRequiredLabelRule: LanguageScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageSchedule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageScheduleRequiredCurrencyRule: LanguageScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageSchedule) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a language schedule.
    final class LanguageScheduleValidator {
        var rules: [any LanguageScheduleRule]

        init(rules: [any LanguageScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageSchedule]) -> [String: [String]] {
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

    static func defaultLanguageScheduleValidator() -> LanguageScheduleValidator {
        return LanguageScheduleValidator(
            rules: [
                LanguageScheduleLimitRangeRule(min: 80, max: 255),
                LanguageScheduleStartsAtRangeRule(min: 32, max: 120),
                LanguageScheduleCodeLengthRule(maxLength: 1000),
                LanguageScheduleCodePrefixRule(prefix: "ACM"),
                LanguageScheduleRequiredLabelRule(message: "language schedule needs an entry"),
                LanguageScheduleRequiredCurrencyRule(message: "language schedule needs this field"),
            ]
        )
    }
}
