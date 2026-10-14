import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending statement notice must pass. Check returns its problems, or none.
    protocol PendingStatementNoticeRule {
        func check(_ item: PendingStatementNotice) -> [String]
    }

    final class PendingStatementNoticeWardLengthRule: PendingStatementNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingStatementNotice) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingStatementNoticeQuantityRangeRule: PendingStatementNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingStatementNotice) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingStatementNoticeCodePrefixRule: PendingStatementNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingStatementNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending statement notice.
    final class PendingStatementNoticeValidator {
        var rules: [any PendingStatementNoticeRule]

        init(rules: [any PendingStatementNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingStatementNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingStatementNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingStatementNotice]) -> [String: [String]] {
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

    static func defaultPendingStatementNoticeValidator() -> PendingStatementNoticeValidator {
        return PendingStatementNoticeValidator(
            rules: [
                PendingStatementNoticeWardLengthRule(maxLength: 16),
                PendingStatementNoticeQuantityRangeRule(min: 80, max: 80),
                PendingStatementNoticeCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
