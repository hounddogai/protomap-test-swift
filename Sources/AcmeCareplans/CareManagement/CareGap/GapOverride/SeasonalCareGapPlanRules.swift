import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal care gap plan must pass. Check returns its problems, or none.
    protocol SeasonalCareGapPlanRule {
        func check(_ item: SeasonalCareGapPlan) -> [String]
    }

    final class SeasonalCareGapPlanRequiredCodeRule: SeasonalCareGapPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCareGapPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCareGapPlanRequiredPhoneRule: SeasonalCareGapPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCareGapPlan) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCareGapPlanAllowedCodeRule: SeasonalCareGapPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalCareGapPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class SeasonalCareGapPlanRequiredTitleRule: SeasonalCareGapPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCareGapPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal care gap plan.
    final class SeasonalCareGapPlanValidator {
        var rules: [any SeasonalCareGapPlanRule]

        init(rules: [any SeasonalCareGapPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCareGapPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalCareGapPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCareGapPlan]) -> [String: [String]] {
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

    static func defaultSeasonalCareGapPlanValidator() -> SeasonalCareGapPlanValidator {
        return SeasonalCareGapPlanValidator(
            rules: [
                SeasonalCareGapPlanRequiredCodeRule(message: "seasonal care gap plan needs an entry"),
                SeasonalCareGapPlanRequiredPhoneRule(message: "seasonal care gap plan needs a value"),
                SeasonalCareGapPlanAllowedCodeRule(allowed: []),
                SeasonalCareGapPlanRequiredTitleRule(message: "seasonal care gap plan needs an entry"),
            ]
        )
    }
}
