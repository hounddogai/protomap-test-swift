import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift notice must pass. Check returns its problems, or none.
    protocol ShiftNoticeRule {
        func check(_ item: ShiftNotice) -> [String]
    }

    final class ShiftNoticeAmountRangeRule: ShiftNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftNotice) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftNoticeLabelLengthRule: ShiftNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftNotice) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftNoticeCodePrefixRule: ShiftNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ShiftNoticeRequiredCodeRule: ShiftNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftNoticeCapacityRangeRule: ShiftNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftNotice) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ShiftNoticeCategoryLengthRule: ShiftNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftNotice) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift notice.
    final class ShiftNoticeValidator {
        var rules: [any ShiftNoticeRule]

        init(rules: [any ShiftNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftNotice]) -> [String: [String]] {
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

    static func defaultShiftNoticeValidator() -> ShiftNoticeValidator {
        return ShiftNoticeValidator(
            rules: [
                ShiftNoticeAmountRangeRule(min: 7.2, max: 3259.0),
                ShiftNoticeLabelLengthRule(maxLength: 16),
                ShiftNoticeCodePrefixRule(prefix: "Q"),
                ShiftNoticeRequiredCodeRule(message: "shift notice needs an entry"),
                ShiftNoticeCapacityRangeRule(min: 255, max: 3600),
                ShiftNoticeCategoryLengthRule(maxLength: 64),
            ]
        )
    }
}
