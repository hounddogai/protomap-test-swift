import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal slot notice must pass. Check returns its problems, or none.
    protocol SeasonalSlotNoticeRule {
        func check(_ item: SeasonalSlotNotice) -> [String]
    }

    final class SeasonalSlotNoticeCodeLengthRule: SeasonalSlotNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSlotNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSlotNoticeLabelLengthRule: SeasonalSlotNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSlotNotice) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSlotNoticeQuantityRangeRule: SeasonalSlotNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSlotNotice) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalSlotNoticeAttemptsRangeRule: SeasonalSlotNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSlotNotice) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a seasonal slot notice.
    final class SeasonalSlotNoticeValidator {
        var rules: [any SeasonalSlotNoticeRule]

        init(rules: [any SeasonalSlotNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSlotNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalSlotNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSlotNotice]) -> [String: [String]] {
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

    static func defaultSeasonalSlotNoticeValidator() -> SeasonalSlotNoticeValidator {
        return SeasonalSlotNoticeValidator(
            rules: [
                SeasonalSlotNoticeCodeLengthRule(maxLength: 16),
                SeasonalSlotNoticeLabelLengthRule(maxLength: 255),
                SeasonalSlotNoticeQuantityRangeRule(min: 16, max: 1000),
                SeasonalSlotNoticeAttemptsRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
