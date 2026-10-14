import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary closure notice must pass. Check returns its problems, or none.
    protocol PrimaryClosureNoticeRule {
        func check(_ item: PrimaryClosureNotice) -> [String]
    }

    final class PrimaryClosureNoticeRequiredCodeRule: PrimaryClosureNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryClosureNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryClosureNoticeRequiredTitleRule: PrimaryClosureNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryClosureNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryClosureNoticeBudgetRangeRule: PrimaryClosureNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryClosureNotice) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryClosureNoticeAllowedCodeRule: PrimaryClosureNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryClosureNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class PrimaryClosureNoticeCodePrefixRule: PrimaryClosureNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryClosureNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryClosureNoticeApprovedGuardRule: PrimaryClosureNoticeRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PrimaryClosureNotice) -> [String] {
            if item.approved && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a primary closure notice.
    final class PrimaryClosureNoticeValidator {
        var rules: [any PrimaryClosureNoticeRule]

        init(rules: [any PrimaryClosureNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryClosureNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryClosureNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryClosureNotice]) -> [String: [String]] {
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

    static func defaultPrimaryClosureNoticeValidator() -> PrimaryClosureNoticeValidator {
        return PrimaryClosureNoticeValidator(
            rules: [
                PrimaryClosureNoticeRequiredCodeRule(message: "primary closure notice needs a value"),
                PrimaryClosureNoticeRequiredTitleRule(message: "primary closure notice needs a value"),
                PrimaryClosureNoticeBudgetRangeRule(min: 7.9, max: 367.9),
                PrimaryClosureNoticeAllowedCodeRule(allowed: ["capped", "seasonal", "adaptive"]),
                PrimaryClosureNoticeCodePrefixRule(prefix: "Q"),
                PrimaryClosureNoticeApprovedGuardRule(limit: 80),
            ]
        )
    }
}
