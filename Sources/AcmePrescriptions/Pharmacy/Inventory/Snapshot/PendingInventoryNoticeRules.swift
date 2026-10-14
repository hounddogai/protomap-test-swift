import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending inventory notice must pass. Check returns its problems, or none.
    protocol PendingInventoryNoticeRule {
        func check(_ item: PendingInventoryNotice) -> [String]
    }

    final class PendingInventoryNoticeCodeLengthRule: PendingInventoryNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingInventoryNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingInventoryNoticeReviewerLengthRule: PendingInventoryNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingInventoryNotice) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingInventoryNoticeVisitMinutesRangeRule: PendingInventoryNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingInventoryNotice) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingInventoryNoticeCodePrefixRule: PendingInventoryNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingInventoryNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingInventoryNoticeRequiredCurrencyRule: PendingInventoryNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingInventoryNotice) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending inventory notice.
    final class PendingInventoryNoticeValidator {
        var rules: [any PendingInventoryNoticeRule]

        init(rules: [any PendingInventoryNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingInventoryNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingInventoryNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingInventoryNotice]) -> [String: [String]] {
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

    static func defaultPendingInventoryNoticeValidator() -> PendingInventoryNoticeValidator {
        return PendingInventoryNoticeValidator(
            rules: [
                PendingInventoryNoticeCodeLengthRule(maxLength: 86400),
                PendingInventoryNoticeReviewerLengthRule(maxLength: 80),
                PendingInventoryNoticeVisitMinutesRangeRule(min: 32, max: 86400),
                PendingInventoryNoticeCodePrefixRule(prefix: "ACM"),
                PendingInventoryNoticeRequiredCurrencyRule(message: "pending inventory notice needs a value"),
            ]
        )
    }
}
