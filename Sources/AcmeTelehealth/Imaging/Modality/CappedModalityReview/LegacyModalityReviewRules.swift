import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy modality review must pass. Check returns its problems, or none.
    protocol LegacyModalityReviewRule {
        func check(_ item: LegacyModalityReview) -> [String]
    }

    final class LegacyModalityReviewPriorityRangeRule: LegacyModalityReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyModalityReview) -> [String] {
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

    final class LegacyModalityReviewPinnedGuardRule: LegacyModalityReviewRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LegacyModalityReview) -> [String] {
            if item.pinned && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class LegacyModalityReviewAllowedLabelRule: LegacyModalityReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyModalityReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    final class LegacyModalityReviewPatientRefLengthRule: LegacyModalityReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyModalityReview) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy modality review.
    final class LegacyModalityReviewValidator {
        var rules: [any LegacyModalityReviewRule]

        init(rules: [any LegacyModalityReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyModalityReview) -> [String] {
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

        func requireValid(_ item: LegacyModalityReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyModalityReview]) -> [String: [String]] {
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

    static func defaultLegacyModalityReviewValidator() -> LegacyModalityReviewValidator {
        return LegacyModalityReviewValidator(
            rules: [
                LegacyModalityReviewPriorityRangeRule(min: 16, max: 1000),
                LegacyModalityReviewPinnedGuardRule(limit: 6.1),
                LegacyModalityReviewAllowedLabelRule(allowed: ["fallback"]),
                LegacyModalityReviewPatientRefLengthRule(maxLength: 120),
            ]
        )
    }
}
