import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending authorization plan must pass. Check returns its problems, or none.
    protocol PendingAuthorizationPlanRule {
        func check(_ item: PendingAuthorizationPlan) -> [String]
    }

    final class PendingAuthorizationPlanCodeLengthRule: PendingAuthorizationPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAuthorizationPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAuthorizationPlanNameLengthRule: PendingAuthorizationPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingAuthorizationPlan) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingAuthorizationPlanCodePrefixRule: PendingAuthorizationPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingAuthorizationPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingAuthorizationPlanRequiredCodeRule: PendingAuthorizationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingAuthorizationPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingAuthorizationPlanRatioRangeRule: PendingAuthorizationPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingAuthorizationPlan) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingAuthorizationPlanRequiredSummaryRule: PendingAuthorizationPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingAuthorizationPlan) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending authorization plan.
    final class PendingAuthorizationPlanValidator {
        var rules: [any PendingAuthorizationPlanRule]

        init(rules: [any PendingAuthorizationPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingAuthorizationPlan) -> [String] {
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

        func requireValid(_ item: PendingAuthorizationPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingAuthorizationPlan]) -> [String: [String]] {
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

    static func defaultPendingAuthorizationPlanValidator() -> PendingAuthorizationPlanValidator {
        return PendingAuthorizationPlanValidator(
            rules: [
                PendingAuthorizationPlanCodeLengthRule(maxLength: 64),
                PendingAuthorizationPlanNameLengthRule(maxLength: 255),
                PendingAuthorizationPlanCodePrefixRule(prefix: "Q"),
                PendingAuthorizationPlanRequiredCodeRule(message: "pending authorization plan needs an entry"),
                PendingAuthorizationPlanRatioRangeRule(min: 9.4, max: 3566.4),
                PendingAuthorizationPlanRequiredSummaryRule(message: "pending authorization plan needs an entry"),
            ]
        )
    }
}
