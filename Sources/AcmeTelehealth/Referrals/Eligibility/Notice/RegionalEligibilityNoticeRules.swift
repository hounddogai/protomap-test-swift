import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional eligibility notice must pass. Check returns its problems, or none.
    protocol RegionalEligibilityNoticeRule {
        func check(_ item: RegionalEligibilityNotice) -> [String]
    }

    final class RegionalEligibilityNoticeExpiresAtRangeRule: RegionalEligibilityNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalEligibilityNotice) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalEligibilityNoticeWeightRangeRule: RegionalEligibilityNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalEligibilityNotice) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalEligibilityNoticeRequiredCodeRule: RegionalEligibilityNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalEligibilityNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalEligibilityNoticeCodeLengthRule: RegionalEligibilityNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalEligibilityNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional eligibility notice.
    final class RegionalEligibilityNoticeValidator {
        var rules: [any RegionalEligibilityNoticeRule]

        init(rules: [any RegionalEligibilityNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalEligibilityNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalEligibilityNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalEligibilityNotice]) -> [String: [String]] {
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

    static func defaultRegionalEligibilityNoticeValidator() -> RegionalEligibilityNoticeValidator {
        return RegionalEligibilityNoticeValidator(
            rules: [
                RegionalEligibilityNoticeExpiresAtRangeRule(min: 80, max: 1000),
                RegionalEligibilityNoticeWeightRangeRule(min: 8.5, max: 949.7),
                RegionalEligibilityNoticeRequiredCodeRule(message: "regional eligibility notice needs a value"),
                RegionalEligibilityNoticeCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
