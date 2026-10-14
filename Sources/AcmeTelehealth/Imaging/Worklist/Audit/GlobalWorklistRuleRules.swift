import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global worklist rule must pass. Check returns its problems, or none.
    protocol GlobalWorklistRuleRule {
        func check(_ item: GlobalWorklistRule) -> [String]
    }

    final class GlobalWorklistRuleAllowedCodeRule: GlobalWorklistRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalWorklistRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class GlobalWorklistRuleCodeLengthRule: GlobalWorklistRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalWorklistRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalWorklistRuleMarginRangeRule: GlobalWorklistRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalWorklistRule) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalWorklistRuleRequiredLabelRule: GlobalWorklistRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalWorklistRule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global worklist rule.
    final class GlobalWorklistRuleValidator {
        var rules: [any GlobalWorklistRuleRule]

        init(rules: [any GlobalWorklistRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalWorklistRule) -> [String] {
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

        func requireValid(_ item: GlobalWorklistRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalWorklistRule]) -> [String: [String]] {
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

    static func defaultGlobalWorklistRuleValidator() -> GlobalWorklistRuleValidator {
        return GlobalWorklistRuleValidator(
            rules: [
                GlobalWorklistRuleAllowedCodeRule(allowed: ["strict", "tiered", "pending"]),
                GlobalWorklistRuleCodeLengthRule(maxLength: 16),
                GlobalWorklistRuleMarginRangeRule(min: 2.2, max: 4619.5),
                GlobalWorklistRuleRequiredLabelRule(message: "global worklist rule needs an entry"),
            ]
        )
    }
}
