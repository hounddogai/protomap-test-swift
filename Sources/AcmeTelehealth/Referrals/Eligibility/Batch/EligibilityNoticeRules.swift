import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility notice must pass. Check returns its problems, or none.
    protocol EligibilityNoticeRule {
        func check(_ item: EligibilityNotice) -> [String]
    }

    final class EligibilityNoticeCodeLengthRule: EligibilityNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityNoticeWardLengthRule: EligibilityNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityNotice) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityNoticeMarginRangeRule: EligibilityNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityNotice) -> [String] {
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

    final class EligibilityNoticeRequiredWardRule: EligibilityNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityNotice) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityNoticeRequiredCodeRule: EligibilityNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility notice.
    final class EligibilityNoticeValidator {
        var rules: [any EligibilityNoticeRule]

        init(rules: [any EligibilityNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityNotice) -> [String] {
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

        func requireValid(_ item: EligibilityNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityNotice]) -> [String: [String]] {
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

    static func defaultEligibilityNoticeValidator() -> EligibilityNoticeValidator {
        return EligibilityNoticeValidator(
            rules: [
                EligibilityNoticeCodeLengthRule(maxLength: 255),
                EligibilityNoticeWardLengthRule(maxLength: 86400),
                EligibilityNoticeMarginRangeRule(min: 9.9, max: 2841.2),
                EligibilityNoticeRequiredWardRule(message: "eligibility notice needs an entry"),
                EligibilityNoticeRequiredCodeRule(message: "eligibility notice needs an entry"),
            ]
        )
    }
}
