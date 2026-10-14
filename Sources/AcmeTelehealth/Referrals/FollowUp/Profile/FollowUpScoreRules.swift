import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up score must pass. Check returns its problems, or none.
    protocol FollowUpScoreRule {
        func check(_ item: FollowUpScore) -> [String]
    }

    final class FollowUpScoreAllowedLabelRule: FollowUpScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FollowUpScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class FollowUpScoreRequiredCodeRule: FollowUpScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpScoreAmountRangeRule: FollowUpScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpScore) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpScoreRequiredBedRule: FollowUpScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpScore) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpScoreLabelLengthRule: FollowUpScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpScore) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up score.
    final class FollowUpScoreValidator {
        var rules: [any FollowUpScoreRule]

        init(rules: [any FollowUpScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpScore]) -> [String: [String]] {
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

    static func defaultFollowUpScoreValidator() -> FollowUpScoreValidator {
        return FollowUpScoreValidator(
            rules: [
                FollowUpScoreAllowedLabelRule(allowed: ["tiered", "seasonal"]),
                FollowUpScoreRequiredCodeRule(message: "follow up score needs an entry"),
                FollowUpScoreAmountRangeRule(min: 4.1, max: 1939.4),
                FollowUpScoreRequiredBedRule(message: "follow up score needs this field"),
                FollowUpScoreLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
