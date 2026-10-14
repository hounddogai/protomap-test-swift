import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan notice must pass. Check returns its problems, or none.
    protocol DischargePlanNoticeRule {
        func check(_ item: DischargePlanNotice) -> [String]
    }

    final class DischargePlanNoticeReviewerLengthRule: DischargePlanNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanNotice) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanNoticeRequiredNameRule: DischargePlanNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanNotice) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanNoticeActiveGuardRule: DischargePlanNoticeRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DischargePlanNotice) -> [String] {
            if item.active && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class DischargePlanNoticeRequiredCodeRule: DischargePlanNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanNoticeCodePrefixRule: DischargePlanNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DischargePlanNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DischargePlanNoticeMarginRangeRule: DischargePlanNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanNotice) -> [String] {
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

    /// Runs every rule of a discharge plan notice.
    final class DischargePlanNoticeValidator {
        var rules: [any DischargePlanNoticeRule]

        init(rules: [any DischargePlanNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanNotice]) -> [String: [String]] {
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

    static func defaultDischargePlanNoticeValidator() -> DischargePlanNoticeValidator {
        return DischargePlanNoticeValidator(
            rules: [
                DischargePlanNoticeReviewerLengthRule(maxLength: 3600),
                DischargePlanNoticeRequiredNameRule(message: "discharge plan notice needs this field"),
                DischargePlanNoticeActiveGuardRule(limit: 255),
                DischargePlanNoticeRequiredCodeRule(message: "discharge plan notice needs a value"),
                DischargePlanNoticeCodePrefixRule(prefix: "REF"),
                DischargePlanNoticeMarginRangeRule(min: 3.7, max: 868.1),
            ]
        )
    }
}
