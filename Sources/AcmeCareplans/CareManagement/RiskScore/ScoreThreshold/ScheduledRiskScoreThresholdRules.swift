import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled risk score threshold must pass. Check returns its problems, or none.
    protocol ScheduledRiskScoreThresholdRule {
        func check(_ item: ScheduledRiskScoreThreshold) -> [String]
    }

    final class ScheduledRiskScoreThresholdRequiredFacilityRule: ScheduledRiskScoreThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRiskScoreThreshold) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledRiskScoreThresholdMarginRangeRule: ScheduledRiskScoreThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRiskScoreThreshold) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledRiskScoreThresholdRequiredTitleRule: ScheduledRiskScoreThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRiskScoreThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled risk score threshold.
    final class ScheduledRiskScoreThresholdValidator {
        var rules: [any ScheduledRiskScoreThresholdRule]

        init(rules: [any ScheduledRiskScoreThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledRiskScoreThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledRiskScoreThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledRiskScoreThreshold]) -> [String: [String]] {
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

    static func defaultScheduledRiskScoreThresholdValidator() -> ScheduledRiskScoreThresholdValidator {
        return ScheduledRiskScoreThresholdValidator(
            rules: [
                ScheduledRiskScoreThresholdRequiredFacilityRule(
                    message: "scheduled risk score threshold needs an entry"
                ),
                ScheduledRiskScoreThresholdMarginRangeRule(min: 2.5, max: 3978.4),
                ScheduledRiskScoreThresholdRequiredTitleRule(message: "scheduled risk score threshold needs an entry"),
            ]
        )
    }
}
