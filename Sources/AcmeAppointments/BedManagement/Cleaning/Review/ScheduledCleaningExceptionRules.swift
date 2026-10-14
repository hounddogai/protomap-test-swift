import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled cleaning exception must pass. Check returns its problems, or none.
    protocol ScheduledCleaningExceptionRule {
        func check(_ item: ScheduledCleaningException) -> [String]
    }

    final class ScheduledCleaningExceptionCodePrefixRule: ScheduledCleaningExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledCleaningException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledCleaningExceptionRequiredBedRule: ScheduledCleaningExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCleaningException) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCleaningExceptionRequiredNameRule: ScheduledCleaningExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCleaningException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCleaningExceptionNameLengthRule: ScheduledCleaningExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCleaningException) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCleaningExceptionReviewerLengthRule: ScheduledCleaningExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCleaningException) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCleaningExceptionGraceDaysRangeRule: ScheduledCleaningExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCleaningException) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled cleaning exception.
    final class ScheduledCleaningExceptionValidator {
        var rules: [any ScheduledCleaningExceptionRule]

        init(rules: [any ScheduledCleaningExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCleaningException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCleaningException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCleaningException]) -> [String: [String]] {
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

    static func defaultScheduledCleaningExceptionValidator() -> ScheduledCleaningExceptionValidator {
        return ScheduledCleaningExceptionValidator(
            rules: [
                ScheduledCleaningExceptionCodePrefixRule(prefix: "OPS"),
                ScheduledCleaningExceptionRequiredBedRule(message: "scheduled cleaning exception needs an entry"),
                ScheduledCleaningExceptionRequiredNameRule(message: "scheduled cleaning exception needs an entry"),
                ScheduledCleaningExceptionNameLengthRule(maxLength: 80),
                ScheduledCleaningExceptionReviewerLengthRule(maxLength: 64),
                ScheduledCleaningExceptionGraceDaysRangeRule(min: 80, max: 255),
            ]
        )
    }
}
