import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census rule must pass. Check returns its problems, or none.
    protocol CensusRuleRule {
        func check(_ item: CensusRule) -> [String]
    }

    final class CensusRuleNameLengthRule: CensusRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusRuleRequiredNameRule: CensusRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusRuleRequiredTitleRule: CensusRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusRuleTitleLengthRule: CensusRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a census rule.
    final class CensusRuleValidator {
        var rules: [any CensusRuleRule]

        init(rules: [any CensusRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusRule) -> [String] {
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

        func requireValid(_ item: CensusRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusRule]) -> [String: [String]] {
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

    static func defaultCensusRuleValidator() -> CensusRuleValidator {
        return CensusRuleValidator(
            rules: [
                CensusRuleNameLengthRule(maxLength: 255),
                CensusRuleRequiredNameRule(message: "census rule needs a value"),
                CensusRuleRequiredTitleRule(message: "census rule needs a value"),
                CensusRuleTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
