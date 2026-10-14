import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation rule must pass. Check returns its problems, or none.
    protocol IsolationRuleRule {
        func check(_ item: IsolationRule) -> [String]
    }

    final class IsolationRuleAllowedExternalRefRule: IsolationRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is blocked"]
            }
            return []
        }
    }

    final class IsolationRuleRequiredCodeRule: IsolationRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationRuleRequiredTitleRule: IsolationRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationRuleTitleLengthRule: IsolationRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationRule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationRuleNotesLengthRule: IsolationRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationRule) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationRuleCodeLengthRule: IsolationRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation rule.
    final class IsolationRuleValidator {
        var rules: [any IsolationRuleRule]

        init(rules: [any IsolationRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationRule]) -> [String: [String]] {
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

    static func defaultIsolationRuleValidator() -> IsolationRuleValidator {
        return IsolationRuleValidator(
            rules: [
                IsolationRuleAllowedExternalRefRule(allowed: ["pending"]),
                IsolationRuleRequiredCodeRule(message: "isolation rule needs an entry"),
                IsolationRuleRequiredTitleRule(message: "isolation rule needs a value"),
                IsolationRuleTitleLengthRule(maxLength: 16),
                IsolationRuleNotesLengthRule(maxLength: 3600),
                IsolationRuleCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
