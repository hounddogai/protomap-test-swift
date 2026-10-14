import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up batch must pass. Check returns its problems, or none.
    protocol FollowUpBatchRule {
        func check(_ item: FollowUpBatch) -> [String]
    }

    final class FollowUpBatchAttemptsRangeRule: FollowUpBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpBatch) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpBatchCodeLengthRule: FollowUpBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpBatchAllowedNameRule: FollowUpBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FollowUpBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    final class FollowUpBatchNameLengthRule: FollowUpBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpBatchRequiredNotesRule: FollowUpBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpBatch) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a follow up batch.
    final class FollowUpBatchValidator {
        var rules: [any FollowUpBatchRule]

        init(rules: [any FollowUpBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpBatch]) -> [String: [String]] {
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

    static func defaultFollowUpBatchValidator() -> FollowUpBatchValidator {
        return FollowUpBatchValidator(
            rules: [
                FollowUpBatchAttemptsRangeRule(min: 16, max: 1000),
                FollowUpBatchCodeLengthRule(maxLength: 64),
                FollowUpBatchAllowedNameRule(allowed: []),
                FollowUpBatchNameLengthRule(maxLength: 80),
                FollowUpBatchRequiredNotesRule(message: "follow up batch needs an entry"),
            ]
        )
    }
}
