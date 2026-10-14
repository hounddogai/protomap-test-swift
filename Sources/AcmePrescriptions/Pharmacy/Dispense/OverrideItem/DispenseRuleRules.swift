import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense rule must pass. Check returns its problems, or none.
    protocol DispenseRuleRule {
        func check(_ item: DispenseRule) -> [String]
    }

    final class DispenseRuleBatchSizeRangeRule: DispenseRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseRule) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseRuleCodeLengthRule: DispenseRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseRuleExternalRefLengthRule: DispenseRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseRule) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseRuleRequiredExternalRefRule: DispenseRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseRule) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a dispense rule.
    final class DispenseRuleValidator {
        var rules: [any DispenseRuleRule]

        init(rules: [any DispenseRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseRule]) -> [String: [String]] {
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

    static func defaultDispenseRuleValidator() -> DispenseRuleValidator {
        return DispenseRuleValidator(
            rules: [
                DispenseRuleBatchSizeRangeRule(min: 64, max: 3600),
                DispenseRuleCodeLengthRule(maxLength: 255),
                DispenseRuleExternalRefLengthRule(maxLength: 64),
                DispenseRuleRequiredExternalRefRule(message: "dispense rule needs an entry"),
            ]
        )
    }
}
