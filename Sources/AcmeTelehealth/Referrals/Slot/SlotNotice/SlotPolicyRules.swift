import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot policy must pass. Check returns its problems, or none.
    protocol SlotPolicyRule {
        func check(_ item: SlotPolicy) -> [String]
    }

    final class SlotPolicyCodePrefixRule: SlotPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SlotPolicyCeilingRangeRule: SlotPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotPolicy) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotPolicyDiscountRangeRule: SlotPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotPolicy) -> [String] {
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

    final class SlotPolicyCodeLengthRule: SlotPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotPolicyTitleLengthRule: SlotPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotPolicy) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot policy.
    final class SlotPolicyValidator {
        var rules: [any SlotPolicyRule]

        init(rules: [any SlotPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotPolicy) -> [String] {
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

        func requireValid(_ item: SlotPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotPolicy]) -> [String: [String]] {
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

    static func defaultSlotPolicyValidator() -> SlotPolicyValidator {
        return SlotPolicyValidator(
            rules: [
                SlotPolicyCodePrefixRule(prefix: "ACM"),
                SlotPolicyCeilingRangeRule(min: 8.8, max: 4767.1),
                SlotPolicyDiscountRangeRule(min: 4.3, max: 1507.7),
                SlotPolicyCodeLengthRule(maxLength: 120),
                SlotPolicyTitleLengthRule(maxLength: 120),
            ]
        )
    }
}
