import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan review must pass. Check returns its problems, or none.
    protocol DischargePlanReviewRule {
        func check(_ item: DischargePlanReview) -> [String]
    }

    final class DischargePlanReviewAllowedCodeRule: DischargePlanReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class DischargePlanReviewRequiredPhoneRule: DischargePlanReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanReview) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanReviewCeilingRangeRule: DischargePlanReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanReview) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanReviewRequiredContactEmailRule: DischargePlanReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanReview) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanReviewRequiredCodeRule: DischargePlanReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan review.
    final class DischargePlanReviewValidator {
        var rules: [any DischargePlanReviewRule]

        init(rules: [any DischargePlanReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanReview) -> [String] {
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

        func requireValid(_ item: DischargePlanReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanReview]) -> [String: [String]] {
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

    static func defaultDischargePlanReviewValidator() -> DischargePlanReviewValidator {
        return DischargePlanReviewValidator(
            rules: [
                DischargePlanReviewAllowedCodeRule(allowed: ["strict", "pending"]),
                DischargePlanReviewRequiredPhoneRule(message: "discharge plan review needs this field"),
                DischargePlanReviewCeilingRangeRule(min: 5.8, max: 1827.4),
                DischargePlanReviewRequiredContactEmailRule(message: "discharge plan review needs an entry"),
                DischargePlanReviewRequiredCodeRule(message: "discharge plan review needs this field"),
            ]
        )
    }
}
