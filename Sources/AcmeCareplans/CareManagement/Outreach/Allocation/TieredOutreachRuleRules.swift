import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered outreach rule must pass. Check returns its problems, or none.
    protocol TieredOutreachRuleRule {
        func check(_ item: TieredOutreachRule) -> [String]
    }

    final class TieredOutreachRuleCodeLengthRule: TieredOutreachRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredOutreachRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredOutreachRuleAllowedCodeRule: TieredOutreachRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredOutreachRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class TieredOutreachRuleRequiredNameRule: TieredOutreachRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOutreachRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered outreach rule.
    final class TieredOutreachRuleValidator {
        var rules: [any TieredOutreachRuleRule]

        init(rules: [any TieredOutreachRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredOutreachRule) -> [String] {
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

        func requireValid(_ item: TieredOutreachRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredOutreachRule]) -> [String: [String]] {
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

    static func defaultTieredOutreachRuleValidator() -> TieredOutreachRuleValidator {
        return TieredOutreachRuleValidator(
            rules: [
                TieredOutreachRuleCodeLengthRule(maxLength: 1000),
                TieredOutreachRuleAllowedCodeRule(allowed: []),
                TieredOutreachRuleRequiredNameRule(message: "tiered outreach rule needs an entry"),
            ]
        )
    }
}
