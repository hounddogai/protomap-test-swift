import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped closure rule must pass. Check returns its problems, or none.
    protocol CappedClosureRuleRule {
        func check(_ item: CappedClosureRule) -> [String]
    }

    final class CappedClosureRuleRequiredLabelRule: CappedClosureRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedClosureRule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedClosureRuleCodePrefixRule: CappedClosureRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedClosureRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedClosureRuleEncounterIDLengthRule: CappedClosureRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClosureRule) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedClosureRuleSourceLengthRule: CappedClosureRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedClosureRule) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped closure rule.
    final class CappedClosureRuleValidator {
        var rules: [any CappedClosureRuleRule]

        init(rules: [any CappedClosureRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedClosureRule) -> [String] {
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

        func requireValid(_ item: CappedClosureRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedClosureRule]) -> [String: [String]] {
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

    static func defaultCappedClosureRuleValidator() -> CappedClosureRuleValidator {
        return CappedClosureRuleValidator(
            rules: [
                CappedClosureRuleRequiredLabelRule(message: "capped closure rule needs an entry"),
                CappedClosureRuleCodePrefixRule(prefix: "Q"),
                CappedClosureRuleEncounterIDLengthRule(maxLength: 80),
                CappedClosureRuleSourceLengthRule(maxLength: 16),
            ]
        )
    }
}
