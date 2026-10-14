import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan rule must pass. Check returns its problems, or none.
    protocol DischargePlanRuleRule {
        func check(_ item: DischargePlanRule) -> [String]
    }

    final class DischargePlanRuleCodePrefixRule: DischargePlanRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DischargePlanRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DischargePlanRuleCodeLengthRule: DischargePlanRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanRuleTitleLengthRule: DischargePlanRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan rule.
    final class DischargePlanRuleValidator {
        var rules: [any DischargePlanRuleRule]

        init(rules: [any DischargePlanRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanRule]) -> [String: [String]] {
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

    static func defaultDischargePlanRuleValidator() -> DischargePlanRuleValidator {
        return DischargePlanRuleValidator(
            rules: [
                DischargePlanRuleCodePrefixRule(prefix: "Q"),
                DischargePlanRuleCodeLengthRule(maxLength: 120),
                DischargePlanRuleTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
