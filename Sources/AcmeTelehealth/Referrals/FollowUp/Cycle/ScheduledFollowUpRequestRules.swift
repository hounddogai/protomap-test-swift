import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled follow up request must pass. Check returns its problems, or none.
    protocol ScheduledFollowUpRequestRule {
        func check(_ item: ScheduledFollowUpRequest) -> [String]
    }

    final class ScheduledFollowUpRequestCodeLengthRule: ScheduledFollowUpRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFollowUpRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpRequestLabelLengthRule: ScheduledFollowUpRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFollowUpRequest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpRequestAllowedCodeRule: ScheduledFollowUpRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledFollowUpRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class ScheduledFollowUpRequestGraceDaysRangeRule: ScheduledFollowUpRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFollowUpRequest) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpRequestRequiredCodeRule: ScheduledFollowUpRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFollowUpRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledFollowUpRequestRequiredEncounterIDRule: ScheduledFollowUpRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFollowUpRequest) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled follow up request.
    final class ScheduledFollowUpRequestValidator {
        var rules: [any ScheduledFollowUpRequestRule]

        init(rules: [any ScheduledFollowUpRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledFollowUpRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledFollowUpRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledFollowUpRequest]) -> [String: [String]] {
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

    static func defaultScheduledFollowUpRequestValidator() -> ScheduledFollowUpRequestValidator {
        return ScheduledFollowUpRequestValidator(
            rules: [
                ScheduledFollowUpRequestCodeLengthRule(maxLength: 1000),
                ScheduledFollowUpRequestLabelLengthRule(maxLength: 255),
                ScheduledFollowUpRequestAllowedCodeRule(allowed: ["adaptive", "default", "legacy"]),
                ScheduledFollowUpRequestGraceDaysRangeRule(min: 64, max: 3600),
                ScheduledFollowUpRequestRequiredCodeRule(message: "scheduled follow up request needs an entry"),
                ScheduledFollowUpRequestRequiredEncounterIDRule(message: "scheduled follow up request needs a value"),
            ]
        )
    }
}
