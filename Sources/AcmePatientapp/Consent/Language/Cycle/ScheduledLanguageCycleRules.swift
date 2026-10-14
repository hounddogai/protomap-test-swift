import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled language cycle must pass. Check returns its problems, or none.
    protocol ScheduledLanguageCycleRule {
        func check(_ item: ScheduledLanguageCycle) -> [String]
    }

    final class ScheduledLanguageCycleRateRangeRule: ScheduledLanguageCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledLanguageCycle) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledLanguageCycleCodePrefixRule: ScheduledLanguageCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledLanguageCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledLanguageCycleRequiredCodeRule: ScheduledLanguageCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledLanguageCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledLanguageCycleTitleLengthRule: ScheduledLanguageCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledLanguageCycle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledLanguageCycleCodeLengthRule: ScheduledLanguageCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledLanguageCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledLanguageCycleRequiredReviewerRule: ScheduledLanguageCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledLanguageCycle) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled language cycle.
    final class ScheduledLanguageCycleValidator {
        var rules: [any ScheduledLanguageCycleRule]

        init(rules: [any ScheduledLanguageCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledLanguageCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledLanguageCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledLanguageCycle]) -> [String: [String]] {
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

    static func defaultScheduledLanguageCycleValidator() -> ScheduledLanguageCycleValidator {
        return ScheduledLanguageCycleValidator(
            rules: [
                ScheduledLanguageCycleRateRangeRule(min: 0.9, max: 3178.1),
                ScheduledLanguageCycleCodePrefixRule(prefix: "REF"),
                ScheduledLanguageCycleRequiredCodeRule(message: "scheduled language cycle needs an entry"),
                ScheduledLanguageCycleTitleLengthRule(maxLength: 1000),
                ScheduledLanguageCycleCodeLengthRule(maxLength: 16),
                ScheduledLanguageCycleRequiredReviewerRule(message: "scheduled language cycle needs this field"),
            ]
        )
    }
}
