import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled overtime review must pass. Check returns its problems, or none.
    protocol ScheduledOvertimeReviewRule {
        func check(_ item: ScheduledOvertimeReview) -> [String]
    }

    final class ScheduledOvertimeReviewRequiredCodeRule: ScheduledOvertimeReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledOvertimeReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledOvertimeReviewAllowedCurrencyRule: ScheduledOvertimeReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledOvertimeReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is stale"]
            }
            return []
        }
    }

    final class ScheduledOvertimeReviewCodeLengthRule: ScheduledOvertimeReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledOvertimeReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledOvertimeReviewOwnerIDLengthRule: ScheduledOvertimeReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledOvertimeReview) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledOvertimeReviewRequiredOwnerIDRule: ScheduledOvertimeReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledOvertimeReview) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledOvertimeReviewDurationMinutesRangeRule: ScheduledOvertimeReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledOvertimeReview) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled overtime review.
    final class ScheduledOvertimeReviewValidator {
        var rules: [any ScheduledOvertimeReviewRule]

        init(rules: [any ScheduledOvertimeReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledOvertimeReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledOvertimeReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledOvertimeReview]) -> [String: [String]] {
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

    static func defaultScheduledOvertimeReviewValidator() -> ScheduledOvertimeReviewValidator {
        return ScheduledOvertimeReviewValidator(
            rules: [
                ScheduledOvertimeReviewRequiredCodeRule(message: "scheduled overtime review needs a value"),
                ScheduledOvertimeReviewAllowedCurrencyRule(allowed: ["global", "capped", "global"]),
                ScheduledOvertimeReviewCodeLengthRule(maxLength: 64),
                ScheduledOvertimeReviewOwnerIDLengthRule(maxLength: 32),
                ScheduledOvertimeReviewRequiredOwnerIDRule(message: "scheduled overtime review needs this field"),
                ScheduledOvertimeReviewDurationMinutesRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
