import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial plan must pass. Check returns its problems, or none.
    protocol DenialPlanRule {
        func check(_ item: DenialPlan) -> [String]
    }

    final class DenialPlanCodePrefixRule: DenialPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DenialPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DenialPlanRequiredCodeRule: DenialPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialPlanRequiredSourceRule: DenialPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialPlan) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialPlanRequiredCountryRule: DenialPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialPlan) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a denial plan.
    final class DenialPlanValidator {
        var rules: [any DenialPlanRule]

        init(rules: [any DenialPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialPlan]) -> [String: [String]] {
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

    static func defaultDenialPlanValidator() -> DenialPlanValidator {
        return DenialPlanValidator(
            rules: [
                DenialPlanCodePrefixRule(prefix: "OPS"),
                DenialPlanRequiredCodeRule(message: "denial plan needs this field"),
                DenialPlanRequiredSourceRule(message: "denial plan needs this field"),
                DenialPlanRequiredCountryRule(message: "denial plan needs an entry"),
            ]
        )
    }
}
