import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped transfer rule must pass. Check returns its problems, or none.
    protocol CappedTransferRuleRule {
        func check(_ item: CappedTransferRule) -> [String]
    }

    final class CappedTransferRuleCodePrefixRule: CappedTransferRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedTransferRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedTransferRuleLimitRangeRule: CappedTransferRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedTransferRule) -> [String] {
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

    final class CappedTransferRuleLabelLengthRule: CappedTransferRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedTransferRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedTransferRuleRequiredRegionRule: CappedTransferRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedTransferRule) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedTransferRuleLocaleLengthRule: CappedTransferRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedTransferRule) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedTransferRuleCodeLengthRule: CappedTransferRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedTransferRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped transfer rule.
    final class CappedTransferRuleValidator {
        var rules: [any CappedTransferRuleRule]

        init(rules: [any CappedTransferRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedTransferRule) -> [String] {
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

        func requireValid(_ item: CappedTransferRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedTransferRule]) -> [String: [String]] {
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

    static func defaultCappedTransferRuleValidator() -> CappedTransferRuleValidator {
        return CappedTransferRuleValidator(
            rules: [
                CappedTransferRuleCodePrefixRule(prefix: "OPS"),
                CappedTransferRuleLimitRangeRule(min: 80, max: 86400),
                CappedTransferRuleLabelLengthRule(maxLength: 120),
                CappedTransferRuleRequiredRegionRule(message: "capped transfer rule needs this field"),
                CappedTransferRuleLocaleLengthRule(maxLength: 80),
                CappedTransferRuleCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
