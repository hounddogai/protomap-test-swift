import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer rule must pass. Check returns its problems, or none.
    protocol TransferRuleRule {
        func check(_ item: TransferRule) -> [String]
    }

    final class TransferRuleRequiredLabelRule: TransferRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferRule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferRuleLimitRangeRule: TransferRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferRule) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TransferRuleRequiredCodeRule: TransferRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferRuleCodeLengthRule: TransferRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferRuleCodePrefixRule: TransferRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TransferRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer rule.
    final class TransferRuleValidator {
        var rules: [any TransferRuleRule]

        init(rules: [any TransferRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferRule) -> [String] {
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

        func requireValid(_ item: TransferRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferRule]) -> [String: [String]] {
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

    static func defaultTransferRuleValidator() -> TransferRuleValidator {
        return TransferRuleValidator(
            rules: [
                TransferRuleRequiredLabelRule(message: "transfer rule needs this field"),
                TransferRuleLimitRangeRule(min: 120, max: 86400),
                TransferRuleRequiredCodeRule(message: "transfer rule needs an entry"),
                TransferRuleCodeLengthRule(maxLength: 32),
                TransferRuleCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
