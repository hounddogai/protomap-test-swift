import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled risk score group must pass. Check returns its problems, or none.
    protocol ScheduledRiskScoreGroupRule {
        func check(_ item: ScheduledRiskScoreGroup) -> [String]
    }

    final class ScheduledRiskScoreGroupBatchSizeRangeRule: ScheduledRiskScoreGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRiskScoreGroup) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledRiskScoreGroupQuantityRangeRule: ScheduledRiskScoreGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRiskScoreGroup) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledRiskScoreGroupRequiredAllergyRule: ScheduledRiskScoreGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRiskScoreGroup) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled risk score group.
    final class ScheduledRiskScoreGroupValidator {
        var rules: [any ScheduledRiskScoreGroupRule]

        init(rules: [any ScheduledRiskScoreGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledRiskScoreGroup) -> [String] {
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

        func requireValid(_ item: ScheduledRiskScoreGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledRiskScoreGroup]) -> [String: [String]] {
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

    static func defaultScheduledRiskScoreGroupValidator() -> ScheduledRiskScoreGroupValidator {
        return ScheduledRiskScoreGroupValidator(
            rules: [
                ScheduledRiskScoreGroupBatchSizeRangeRule(min: 80, max: 3600),
                ScheduledRiskScoreGroupQuantityRangeRule(min: 32, max: 255),
                ScheduledRiskScoreGroupRequiredAllergyRule(message: "scheduled risk score group needs this field"),
            ]
        )
    }
}
