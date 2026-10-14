import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global acuity plan rule must pass. Check returns its problems, or none.
    protocol GlobalAcuityPlanRuleRule {
        func check(_ item: GlobalAcuityPlanRule) -> [String]
    }

    final class GlobalAcuityPlanRuleCodeLengthRule: GlobalAcuityPlanRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAcuityPlanRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAcuityPlanRuleTimezoneLengthRule: GlobalAcuityPlanRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAcuityPlanRule) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAcuityPlanRuleCeilingRangeRule: GlobalAcuityPlanRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalAcuityPlanRule) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalAcuityPlanRuleRequiredTimezoneRule: GlobalAcuityPlanRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAcuityPlanRule) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAcuityPlanRuleAllowedTitleRule: GlobalAcuityPlanRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalAcuityPlanRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a global acuity plan rule.
    final class GlobalAcuityPlanRuleValidator {
        var rules: [any GlobalAcuityPlanRuleRule]

        init(rules: [any GlobalAcuityPlanRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAcuityPlanRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalAcuityPlanRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAcuityPlanRule]) -> [String: [String]] {
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

    static func defaultGlobalAcuityPlanRuleValidator() -> GlobalAcuityPlanRuleValidator {
        return GlobalAcuityPlanRuleValidator(
            rules: [
                GlobalAcuityPlanRuleCodeLengthRule(maxLength: 16),
                GlobalAcuityPlanRuleTimezoneLengthRule(maxLength: 32),
                GlobalAcuityPlanRuleCeilingRangeRule(min: 6.5, max: 1916.3),
                GlobalAcuityPlanRuleRequiredTimezoneRule(message: "global acuity plan rule needs this field"),
                GlobalAcuityPlanRuleAllowedTitleRule(allowed: ["adaptive"]),
            ]
        )
    }
}
