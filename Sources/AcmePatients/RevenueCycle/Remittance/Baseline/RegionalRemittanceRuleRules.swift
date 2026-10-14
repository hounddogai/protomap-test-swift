import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional remittance rule must pass. Check returns its problems, or none.
    protocol RegionalRemittanceRuleRule {
        func check(_ item: RegionalRemittanceRule) -> [String]
    }

    final class RegionalRemittanceRuleVisitMinutesRangeRule: RegionalRemittanceRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRemittanceRule) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalRemittanceRuleAllowedLabelRule: RegionalRemittanceRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalRemittanceRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    final class RegionalRemittanceRuleRequiredCodeRule: RegionalRemittanceRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRemittanceRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional remittance rule.
    final class RegionalRemittanceRuleValidator {
        var rules: [any RegionalRemittanceRuleRule]

        init(rules: [any RegionalRemittanceRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRemittanceRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalRemittanceRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRemittanceRule]) -> [String: [String]] {
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

    static func defaultRegionalRemittanceRuleValidator() -> RegionalRemittanceRuleValidator {
        return RegionalRemittanceRuleValidator(
            rules: [
                RegionalRemittanceRuleVisitMinutesRangeRule(min: 64, max: 120),
                RegionalRemittanceRuleAllowedLabelRule(allowed: []),
                RegionalRemittanceRuleRequiredCodeRule(message: "regional remittance rule needs a value"),
            ]
        )
    }
}
