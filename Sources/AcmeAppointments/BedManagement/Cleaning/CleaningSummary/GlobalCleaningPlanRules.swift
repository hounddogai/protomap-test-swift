import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global cleaning plan must pass. Check returns its problems, or none.
    protocol GlobalCleaningPlanRule {
        func check(_ item: GlobalCleaningPlan) -> [String]
    }

    final class GlobalCleaningPlanRequiredTitleRule: GlobalCleaningPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCleaningPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCleaningPlanRequiredCodeRule: GlobalCleaningPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCleaningPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalCleaningPlanAllowedCodeRule: GlobalCleaningPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalCleaningPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class GlobalCleaningPlanChannelLengthRule: GlobalCleaningPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCleaningPlan) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCleaningPlanCodePrefixRule: GlobalCleaningPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalCleaningPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalCleaningPlanCeilingRangeRule: GlobalCleaningPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCleaningPlan) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a global cleaning plan.
    final class GlobalCleaningPlanValidator {
        var rules: [any GlobalCleaningPlanRule]

        init(rules: [any GlobalCleaningPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCleaningPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalCleaningPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCleaningPlan]) -> [String: [String]] {
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

    static func defaultGlobalCleaningPlanValidator() -> GlobalCleaningPlanValidator {
        return GlobalCleaningPlanValidator(
            rules: [
                GlobalCleaningPlanRequiredTitleRule(message: "global cleaning plan needs an entry"),
                GlobalCleaningPlanRequiredCodeRule(message: "global cleaning plan needs an entry"),
                GlobalCleaningPlanAllowedCodeRule(allowed: ["regional", "lenient", "capped"]),
                GlobalCleaningPlanChannelLengthRule(maxLength: 3600),
                GlobalCleaningPlanCodePrefixRule(prefix: "ACM"),
                GlobalCleaningPlanCeilingRangeRule(min: 6.6, max: 2256.1),
            ]
        )
    }
}
