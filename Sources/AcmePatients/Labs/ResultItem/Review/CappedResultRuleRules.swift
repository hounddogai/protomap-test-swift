import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped result rule must pass. Check returns its problems, or none.
    protocol CappedResultRuleRule {
        func check(_ item: CappedResultRule) -> [String]
    }

    final class CappedResultRuleRequiredSourceRule: CappedResultRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedResultRule) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedResultRuleCategoryLengthRule: CappedResultRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedResultRule) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedResultRuleRequiredCodeRule: CappedResultRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedResultRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedResultRuleRequiredNameRule: CappedResultRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedResultRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedResultRuleRevisionRangeRule: CappedResultRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedResultRule) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped result rule.
    final class CappedResultRuleValidator {
        var rules: [any CappedResultRuleRule]

        init(rules: [any CappedResultRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedResultRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedResultRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedResultRule]) -> [String: [String]] {
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

    static func defaultCappedResultRuleValidator() -> CappedResultRuleValidator {
        return CappedResultRuleValidator(
            rules: [
                CappedResultRuleRequiredSourceRule(message: "capped result rule needs an entry"),
                CappedResultRuleCategoryLengthRule(maxLength: 16),
                CappedResultRuleRequiredCodeRule(message: "capped result rule needs an entry"),
                CappedResultRuleRequiredNameRule(message: "capped result rule needs this field"),
                CappedResultRuleRevisionRangeRule(min: 16, max: 3600),
            ]
        )
    }
}
