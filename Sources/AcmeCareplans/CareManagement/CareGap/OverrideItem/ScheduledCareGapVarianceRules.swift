import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled care gap variance must pass. Check returns its problems, or none.
    protocol ScheduledCareGapVarianceRule {
        func check(_ item: ScheduledCareGapVariance) -> [String]
    }

    final class ScheduledCareGapVarianceAllowedReviewerRule: ScheduledCareGapVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledCareGapVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is unknown"]
            }
            return []
        }
    }

    final class ScheduledCareGapVarianceCodeLengthRule: ScheduledCareGapVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareGapVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareGapVarianceRequiredAllergyRule: ScheduledCareGapVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareGapVariance) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCareGapVariancePriorityRangeRule: ScheduledCareGapVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCareGapVariance) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled care gap variance.
    final class ScheduledCareGapVarianceValidator {
        var rules: [any ScheduledCareGapVarianceRule]

        init(rules: [any ScheduledCareGapVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCareGapVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCareGapVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCareGapVariance]) -> [String: [String]] {
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

    static func defaultScheduledCareGapVarianceValidator() -> ScheduledCareGapVarianceValidator {
        return ScheduledCareGapVarianceValidator(
            rules: [
                ScheduledCareGapVarianceAllowedReviewerRule(allowed: []),
                ScheduledCareGapVarianceCodeLengthRule(maxLength: 16),
                ScheduledCareGapVarianceRequiredAllergyRule(message: "scheduled care gap variance needs a value"),
                ScheduledCareGapVariancePriorityRangeRule(min: 16, max: 64),
            ]
        )
    }
}
