import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement notice must pass. Check returns its problems, or none.
    protocol StatementNoticeRule {
        func check(_ item: StatementNotice) -> [String]
    }

    final class StatementNoticeLimitRangeRule: StatementNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementNotice) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementNoticeNameLengthRule: StatementNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementNotice) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementNoticeCodeLengthRule: StatementNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement notice.
    final class StatementNoticeValidator {
        var rules: [any StatementNoticeRule]

        init(rules: [any StatementNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementNotice]) -> [String: [String]] {
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

    static func defaultStatementNoticeValidator() -> StatementNoticeValidator {
        return StatementNoticeValidator(
            rules: [
                StatementNoticeLimitRangeRule(min: 80, max: 1000),
                StatementNoticeNameLengthRule(maxLength: 120),
                StatementNoticeCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
