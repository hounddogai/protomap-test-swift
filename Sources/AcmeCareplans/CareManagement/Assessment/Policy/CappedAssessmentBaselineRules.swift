import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped assessment baseline must pass. Check returns its problems, or none.
    protocol CappedAssessmentBaselineRule {
        func check(_ item: CappedAssessmentBaseline) -> [String]
    }

    final class CappedAssessmentBaselineCapacityRangeRule: CappedAssessmentBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedAssessmentBaseline) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedAssessmentBaselineAllowedReviewerRule: CappedAssessmentBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedAssessmentBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is duplicated"]
            }
            return []
        }
    }

    final class CappedAssessmentBaselineRequiredBedRule: CappedAssessmentBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedAssessmentBaseline) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedAssessmentBaselineExpiresAtRangeRule: CappedAssessmentBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedAssessmentBaseline) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedAssessmentBaselineCopayRangeRule: CappedAssessmentBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedAssessmentBaseline) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedAssessmentBaselineRequiredLabelRule: CappedAssessmentBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedAssessmentBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped assessment baseline.
    final class CappedAssessmentBaselineValidator {
        var rules: [any CappedAssessmentBaselineRule]

        init(rules: [any CappedAssessmentBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedAssessmentBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedAssessmentBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedAssessmentBaseline]) -> [String: [String]] {
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

    static func defaultCappedAssessmentBaselineValidator() -> CappedAssessmentBaselineValidator {
        return CappedAssessmentBaselineValidator(
            rules: [
                CappedAssessmentBaselineCapacityRangeRule(min: 16, max: 16),
                CappedAssessmentBaselineAllowedReviewerRule(allowed: ["lenient", "tiered", "scheduled"]),
                CappedAssessmentBaselineRequiredBedRule(message: "capped assessment baseline needs a value"),
                CappedAssessmentBaselineExpiresAtRangeRule(min: 80, max: 1000),
                CappedAssessmentBaselineCopayRangeRule(min: 4.1, max: 3473.5),
                CappedAssessmentBaselineRequiredLabelRule(message: "capped assessment baseline needs an entry"),
            ]
        )
    }
}
