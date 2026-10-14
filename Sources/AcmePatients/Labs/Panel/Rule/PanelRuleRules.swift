import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel rule must pass. Check returns its problems, or none.
    protocol PanelRuleRule {
        func check(_ item: PanelRule) -> [String]
    }

    final class PanelRuleNameLengthRule: PanelRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelRuleRequiredCodeRule: PanelRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PanelRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PanelRuleAllowedNameRule: PanelRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PanelRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a panel rule.
    final class PanelRuleValidator {
        var rules: [any PanelRuleRule]

        init(rules: [any PanelRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelRule) -> [String] {
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

        func requireValid(_ item: PanelRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelRule]) -> [String: [String]] {
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

    static func defaultPanelRuleValidator() -> PanelRuleValidator {
        return PanelRuleValidator(
            rules: [
                PanelRuleNameLengthRule(maxLength: 80),
                PanelRuleRequiredCodeRule(message: "panel rule needs an entry"),
                PanelRuleAllowedNameRule(allowed: ["legacy", "primary"]),
            ]
        )
    }
}
