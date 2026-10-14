import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient study rule must pass. Check returns its problems, or none.
    protocol LenientStudyRuleRule {
        func check(_ item: LenientStudyRule) -> [String]
    }

    final class LenientStudyRulePriorityRangeRule: LenientStudyRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientStudyRule) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientStudyRuleCodePrefixRule: LenientStudyRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientStudyRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientStudyRuleLabelLengthRule: LenientStudyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientStudyRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientStudyRuleDiscountRangeRule: LenientStudyRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientStudyRule) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientStudyRuleRequiredCodeRule: LenientStudyRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientStudyRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient study rule.
    final class LenientStudyRuleValidator {
        var rules: [any LenientStudyRuleRule]

        init(rules: [any LenientStudyRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientStudyRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientStudyRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientStudyRule]) -> [String: [String]] {
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

    static func defaultLenientStudyRuleValidator() -> LenientStudyRuleValidator {
        return LenientStudyRuleValidator(
            rules: [
                LenientStudyRulePriorityRangeRule(min: 64, max: 1000),
                LenientStudyRuleCodePrefixRule(prefix: "OPS"),
                LenientStudyRuleLabelLengthRule(maxLength: 1000),
                LenientStudyRuleDiscountRangeRule(min: 9.0, max: 2571.7),
                LenientStudyRuleRequiredCodeRule(message: "lenient study rule needs this field"),
            ]
        )
    }
}
