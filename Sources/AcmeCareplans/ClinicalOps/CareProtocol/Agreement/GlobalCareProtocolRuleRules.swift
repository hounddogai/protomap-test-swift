import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global care protocol rule must pass. Check returns its problems, or none.
    protocol GlobalCareProtocolRuleRule {
        func check(_ item: GlobalCareProtocolRule) -> [String]
    }

    final class GlobalCareProtocolRuleCodeLengthRule: GlobalCareProtocolRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCareProtocolRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCareProtocolRuleTitleLengthRule: GlobalCareProtocolRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCareProtocolRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCareProtocolRuleRequiredChecksumRule: GlobalCareProtocolRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCareProtocolRule) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global care protocol rule.
    final class GlobalCareProtocolRuleValidator {
        var rules: [any GlobalCareProtocolRuleRule]

        init(rules: [any GlobalCareProtocolRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCareProtocolRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalCareProtocolRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCareProtocolRule]) -> [String: [String]] {
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

    static func defaultGlobalCareProtocolRuleValidator() -> GlobalCareProtocolRuleValidator {
        return GlobalCareProtocolRuleValidator(
            rules: [
                GlobalCareProtocolRuleCodeLengthRule(maxLength: 64),
                GlobalCareProtocolRuleTitleLengthRule(maxLength: 3600),
                GlobalCareProtocolRuleRequiredChecksumRule(message: "global care protocol rule needs a value"),
            ]
        )
    }
}
