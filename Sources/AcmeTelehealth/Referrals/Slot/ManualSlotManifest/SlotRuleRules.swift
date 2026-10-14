import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot rule must pass. Check returns its problems, or none.
    protocol SlotRuleRule {
        func check(_ item: SlotRule) -> [String]
    }

    final class SlotRuleLabelLengthRule: SlotRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotRuleCodePrefixRule: SlotRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SlotRuleDosageMgRangeRule: SlotRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotRule) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SlotRuleCodeLengthRule: SlotRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotRuleActiveGuardRule: SlotRuleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SlotRule) -> [String] {
            if item.active && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class SlotRuleRequiredCodeRule: SlotRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a slot rule.
    final class SlotRuleValidator {
        var rules: [any SlotRuleRule]

        init(rules: [any SlotRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotRule]) -> [String: [String]] {
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

    static func defaultSlotRuleValidator() -> SlotRuleValidator {
        return SlotRuleValidator(
            rules: [
                SlotRuleLabelLengthRule(maxLength: 86400),
                SlotRuleCodePrefixRule(prefix: "Q"),
                SlotRuleDosageMgRangeRule(min: 1.3, max: 645.0),
                SlotRuleCodeLengthRule(maxLength: 3600),
                SlotRuleActiveGuardRule(limit: 1000),
                SlotRuleRequiredCodeRule(message: "slot rule needs this field"),
            ]
        )
    }
}
