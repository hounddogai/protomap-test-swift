import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped worklist notice must pass. Check returns its problems, or none.
    protocol CappedWorklistNoticeRule {
        func check(_ item: CappedWorklistNotice) -> [String]
    }

    final class CappedWorklistNoticeMarginRangeRule: CappedWorklistNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedWorklistNotice) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedWorklistNoticeApprovedGuardRule: CappedWorklistNoticeRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CappedWorklistNotice) -> [String] {
            if item.approved && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class CappedWorklistNoticeRequiredReviewerRule: CappedWorklistNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedWorklistNotice) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedWorklistNoticeCodePrefixRule: CappedWorklistNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedWorklistNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedWorklistNoticeRequiredCodeRule: CappedWorklistNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedWorklistNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedWorklistNoticePriorityRangeRule: CappedWorklistNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedWorklistNotice) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a capped worklist notice.
    final class CappedWorklistNoticeValidator {
        var rules: [any CappedWorklistNoticeRule]

        init(rules: [any CappedWorklistNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedWorklistNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedWorklistNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedWorklistNotice]) -> [String: [String]] {
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

    static func defaultCappedWorklistNoticeValidator() -> CappedWorklistNoticeValidator {
        return CappedWorklistNoticeValidator(
            rules: [
                CappedWorklistNoticeMarginRangeRule(min: 8.6, max: 3562.6),
                CappedWorklistNoticeApprovedGuardRule(limit: 9.4),
                CappedWorklistNoticeRequiredReviewerRule(message: "capped worklist notice needs an entry"),
                CappedWorklistNoticeCodePrefixRule(prefix: "ACM"),
                CappedWorklistNoticeRequiredCodeRule(message: "capped worklist notice needs this field"),
                CappedWorklistNoticePriorityRangeRule(min: 32, max: 64),
            ]
        )
    }
}
