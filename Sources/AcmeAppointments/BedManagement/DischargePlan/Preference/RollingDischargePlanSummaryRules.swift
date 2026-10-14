import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling discharge plan summary must pass. Check returns its problems, or none.
    protocol RollingDischargePlanSummaryRule {
        func check(_ item: RollingDischargePlanSummary) -> [String]
    }

    final class RollingDischargePlanSummaryMarginRangeRule: RollingDischargePlanSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingDischargePlanSummary) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingDischargePlanSummaryRequiredTitleRule: RollingDischargePlanSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDischargePlanSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDischargePlanSummaryCodePrefixRule: RollingDischargePlanSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingDischargePlanSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling discharge plan summary.
    final class RollingDischargePlanSummaryValidator {
        var rules: [any RollingDischargePlanSummaryRule]

        init(rules: [any RollingDischargePlanSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingDischargePlanSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingDischargePlanSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingDischargePlanSummary]) -> [String: [String]] {
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

    static func defaultRollingDischargePlanSummaryValidator() -> RollingDischargePlanSummaryValidator {
        return RollingDischargePlanSummaryValidator(
            rules: [
                RollingDischargePlanSummaryMarginRangeRule(min: 5.3, max: 3919.1),
                RollingDischargePlanSummaryRequiredTitleRule(
                    message: "rolling discharge plan summary needs this field"
                ),
                RollingDischargePlanSummaryCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
