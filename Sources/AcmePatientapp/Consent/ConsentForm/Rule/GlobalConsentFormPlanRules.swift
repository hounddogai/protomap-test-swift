import AcmePlatform
import Foundation

extension Consent {
    /// A rule a global consent form plan must pass. Check returns its problems, or none.
    protocol GlobalConsentFormPlanRule {
        func check(_ item: GlobalConsentFormPlan) -> [String]
    }

    final class GlobalConsentFormPlanVisitMinutesRangeRule: GlobalConsentFormPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalConsentFormPlan) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalConsentFormPlanCodePrefixRule: GlobalConsentFormPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalConsentFormPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalConsentFormPlanRequiredReviewerRule: GlobalConsentFormPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalConsentFormPlan) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalConsentFormPlanBatchSizeRangeRule: GlobalConsentFormPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalConsentFormPlan) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global consent form plan.
    final class GlobalConsentFormPlanValidator {
        var rules: [any GlobalConsentFormPlanRule]

        init(rules: [any GlobalConsentFormPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalConsentFormPlan) -> [String] {
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

        func requireValid(_ item: GlobalConsentFormPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalConsentFormPlan]) -> [String: [String]] {
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

    static func defaultGlobalConsentFormPlanValidator() -> GlobalConsentFormPlanValidator {
        return GlobalConsentFormPlanValidator(
            rules: [
                GlobalConsentFormPlanVisitMinutesRangeRule(min: 64, max: 3600),
                GlobalConsentFormPlanCodePrefixRule(prefix: "X"),
                GlobalConsentFormPlanRequiredReviewerRule(message: "global consent form plan needs a value"),
                GlobalConsentFormPlanBatchSizeRangeRule(min: 80, max: 120),
            ]
        )
    }
}
