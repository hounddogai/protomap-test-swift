import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped follow up target must pass. Check returns its problems, or none.
    protocol CappedFollowUpTargetRule {
        func check(_ item: CappedFollowUpTarget) -> [String]
    }

    final class CappedFollowUpTargetRequiredReviewerRule: CappedFollowUpTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedFollowUpTarget) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedFollowUpTargetCodeLengthRule: CappedFollowUpTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedFollowUpTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedFollowUpTargetGraceDaysRangeRule: CappedFollowUpTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedFollowUpTarget) -> [String] {
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

    final class CappedFollowUpTargetCodePrefixRule: CappedFollowUpTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedFollowUpTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedFollowUpTargetReviewerLengthRule: CappedFollowUpTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedFollowUpTarget) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped follow up target.
    final class CappedFollowUpTargetValidator {
        var rules: [any CappedFollowUpTargetRule]

        init(rules: [any CappedFollowUpTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedFollowUpTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedFollowUpTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedFollowUpTarget]) -> [String: [String]] {
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

    static func defaultCappedFollowUpTargetValidator() -> CappedFollowUpTargetValidator {
        return CappedFollowUpTargetValidator(
            rules: [
                CappedFollowUpTargetRequiredReviewerRule(message: "capped follow up target needs a value"),
                CappedFollowUpTargetCodeLengthRule(maxLength: 3600),
                CappedFollowUpTargetGraceDaysRangeRule(min: 120, max: 86400),
                CappedFollowUpTargetCodePrefixRule(prefix: "ACM"),
                CappedFollowUpTargetReviewerLengthRule(maxLength: 32),
            ]
        )
    }
}
