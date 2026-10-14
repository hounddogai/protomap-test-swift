import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled reference range rule must pass. Check returns its problems, or none.
    protocol ScheduledReferenceRangeRuleRule {
        func check(_ item: ScheduledReferenceRangeRule) -> [String]
    }

    final class ScheduledReferenceRangeRuleRequiredChecksumRule: ScheduledReferenceRangeRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledReferenceRangeRule) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeRuleCodePrefixRule: ScheduledReferenceRangeRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledReferenceRangeRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeRuleSpecialtyLengthRule: ScheduledReferenceRangeRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledReferenceRangeRule) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeRuleNameLengthRule: ScheduledReferenceRangeRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledReferenceRangeRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeRuleRequiredCodeRule: ScheduledReferenceRangeRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledReferenceRangeRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeRuleAmountRangeRule: ScheduledReferenceRangeRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledReferenceRangeRule) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled reference range rule.
    final class ScheduledReferenceRangeRuleValidator {
        var rules: [any ScheduledReferenceRangeRuleRule]

        init(rules: [any ScheduledReferenceRangeRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledReferenceRangeRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledReferenceRangeRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledReferenceRangeRule]) -> [String: [String]] {
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

    static func defaultScheduledReferenceRangeRuleValidator() -> ScheduledReferenceRangeRuleValidator {
        return ScheduledReferenceRangeRuleValidator(
            rules: [
                ScheduledReferenceRangeRuleRequiredChecksumRule(
                    message: "scheduled reference range rule needs this field"
                ),
                ScheduledReferenceRangeRuleCodePrefixRule(prefix: "X"),
                ScheduledReferenceRangeRuleSpecialtyLengthRule(maxLength: 120),
                ScheduledReferenceRangeRuleNameLengthRule(maxLength: 16),
                ScheduledReferenceRangeRuleRequiredCodeRule(message: "scheduled reference range rule needs an entry"),
                ScheduledReferenceRangeRuleAmountRangeRule(min: 2.6, max: 3001.3),
            ]
        )
    }
}
