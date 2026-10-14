import AcmePlatform
import Foundation

extension Consent {
    /// A rule a global disclosure rule must pass. Check returns its problems, or none.
    protocol GlobalDisclosureRuleRule {
        func check(_ item: GlobalDisclosureRule) -> [String]
    }

    final class GlobalDisclosureRuleCodeLengthRule: GlobalDisclosureRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDisclosureRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDisclosureRuleRequiredLabelRule: GlobalDisclosureRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDisclosureRule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDisclosureRuleLabelLengthRule: GlobalDisclosureRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDisclosureRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDisclosureRuleAllowedLabelRule: GlobalDisclosureRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalDisclosureRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a global disclosure rule.
    final class GlobalDisclosureRuleValidator {
        var rules: [any GlobalDisclosureRuleRule]

        init(rules: [any GlobalDisclosureRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDisclosureRule) -> [String] {
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

        func requireValid(_ item: GlobalDisclosureRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDisclosureRule]) -> [String: [String]] {
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

    static func defaultGlobalDisclosureRuleValidator() -> GlobalDisclosureRuleValidator {
        return GlobalDisclosureRuleValidator(
            rules: [
                GlobalDisclosureRuleCodeLengthRule(maxLength: 1000),
                GlobalDisclosureRuleRequiredLabelRule(message: "global disclosure rule needs an entry"),
                GlobalDisclosureRuleLabelLengthRule(maxLength: 255),
                GlobalDisclosureRuleAllowedLabelRule(allowed: ["lenient"]),
            ]
        )
    }
}
