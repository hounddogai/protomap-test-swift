import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled goal estimate must pass. Check returns its problems, or none.
    protocol ScheduledGoalEstimateRule {
        func check(_ item: ScheduledGoalEstimate) -> [String]
    }

    final class ScheduledGoalEstimateRegionLengthRule: ScheduledGoalEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledGoalEstimate) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledGoalEstimateCategoryLengthRule: ScheduledGoalEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledGoalEstimate) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledGoalEstimateRequiredCodeRule: ScheduledGoalEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledGoalEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledGoalEstimateNameLengthRule: ScheduledGoalEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledGoalEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledGoalEstimateAllowedNameRule: ScheduledGoalEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledGoalEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled goal estimate.
    final class ScheduledGoalEstimateValidator {
        var rules: [any ScheduledGoalEstimateRule]

        init(rules: [any ScheduledGoalEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledGoalEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledGoalEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledGoalEstimate]) -> [String: [String]] {
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

    static func defaultScheduledGoalEstimateValidator() -> ScheduledGoalEstimateValidator {
        return ScheduledGoalEstimateValidator(
            rules: [
                ScheduledGoalEstimateRegionLengthRule(maxLength: 255),
                ScheduledGoalEstimateCategoryLengthRule(maxLength: 16),
                ScheduledGoalEstimateRequiredCodeRule(message: "scheduled goal estimate needs an entry"),
                ScheduledGoalEstimateNameLengthRule(maxLength: 1000),
                ScheduledGoalEstimateAllowedNameRule(allowed: ["lenient"]),
            ]
        )
    }
}
