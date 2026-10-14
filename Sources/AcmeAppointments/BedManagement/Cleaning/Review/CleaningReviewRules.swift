import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning review must pass. Check returns its problems, or none.
    protocol CleaningReviewRule {
        func check(_ item: CleaningReview) -> [String]
    }

    final class CleaningReviewRequiredPhoneRule: CleaningReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningReview) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningReviewVisibleGuardRule: CleaningReviewRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CleaningReview) -> [String] {
            if item.visible && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class CleaningReviewCodeLengthRule: CleaningReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningReviewPhoneLengthRule: CleaningReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningReview) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningReviewRequiredNameRule: CleaningReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning review.
    final class CleaningReviewValidator {
        var rules: [any CleaningReviewRule]

        init(rules: [any CleaningReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningReview]) -> [String: [String]] {
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

    static func defaultCleaningReviewValidator() -> CleaningReviewValidator {
        return CleaningReviewValidator(
            rules: [
                CleaningReviewRequiredPhoneRule(message: "cleaning review needs this field"),
                CleaningReviewVisibleGuardRule(limit: 8.8),
                CleaningReviewCodeLengthRule(maxLength: 16),
                CleaningReviewPhoneLengthRule(maxLength: 120),
                CleaningReviewRequiredNameRule(message: "cleaning review needs a value"),
            ]
        )
    }
}
