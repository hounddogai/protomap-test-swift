import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a scheduled recall profile must pass. Check returns its problems, or none.
    protocol ScheduledRecallProfileRule {
        func check(_ item: ScheduledRecallProfile) -> [String]
    }

    final class ScheduledRecallProfileGraceDaysRangeRule: ScheduledRecallProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRecallProfile) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledRecallProfileTitleLengthRule: ScheduledRecallProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledRecallProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledRecallProfileAmountRangeRule: ScheduledRecallProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRecallProfile) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledRecallProfileRequiredCodeRule: ScheduledRecallProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRecallProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledRecallProfileAllowedTitleRule: ScheduledRecallProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledRecallProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled recall profile.
    final class ScheduledRecallProfileValidator {
        var rules: [any ScheduledRecallProfileRule]

        init(rules: [any ScheduledRecallProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledRecallProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledRecallProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledRecallProfile]) -> [String: [String]] {
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

    static func defaultScheduledRecallProfileValidator() -> ScheduledRecallProfileValidator {
        return ScheduledRecallProfileValidator(
            rules: [
                ScheduledRecallProfileGraceDaysRangeRule(min: 16, max: 86400),
                ScheduledRecallProfileTitleLengthRule(maxLength: 16),
                ScheduledRecallProfileAmountRangeRule(min: 7.9, max: 3047.0),
                ScheduledRecallProfileRequiredCodeRule(message: "scheduled recall profile needs an entry"),
                ScheduledRecallProfileAllowedTitleRule(allowed: ["scheduled", "weighted", "default"]),
            ]
        )
    }
}
