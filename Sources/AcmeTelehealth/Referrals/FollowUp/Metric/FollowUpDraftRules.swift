import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up draft must pass. Check returns its problems, or none.
    protocol FollowUpDraftRule {
        func check(_ item: FollowUpDraft) -> [String]
    }

    final class FollowUpDraftCeilingRangeRule: FollowUpDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpDraft) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpDraftScoreRangeRule: FollowUpDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpDraft) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpDraftCodeLengthRule: FollowUpDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up draft.
    final class FollowUpDraftValidator {
        var rules: [any FollowUpDraftRule]

        init(rules: [any FollowUpDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpDraft]) -> [String: [String]] {
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

    static func defaultFollowUpDraftValidator() -> FollowUpDraftValidator {
        return FollowUpDraftValidator(
            rules: [
                FollowUpDraftCeilingRangeRule(min: 2.0, max: 2562.7),
                FollowUpDraftScoreRangeRule(min: 4.7, max: 4988.5),
                FollowUpDraftCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
