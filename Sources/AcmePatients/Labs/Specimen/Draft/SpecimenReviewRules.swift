import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen review must pass. Check returns its problems, or none.
    protocol SpecimenReviewRule {
        func check(_ item: SpecimenReview) -> [String]
    }

    final class SpecimenReviewRequiredDescriptionRule: SpecimenReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenReview) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenReviewRequiredLabelRule: SpecimenReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenReviewDescriptionLengthRule: SpecimenReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenReview) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenReviewAllowedCodeRule: SpecimenReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen review.
    final class SpecimenReviewValidator {
        var rules: [any SpecimenReviewRule]

        init(rules: [any SpecimenReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenReview]) -> [String: [String]] {
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

    static func defaultSpecimenReviewValidator() -> SpecimenReviewValidator {
        return SpecimenReviewValidator(
            rules: [
                SpecimenReviewRequiredDescriptionRule(message: "specimen review needs an entry"),
                SpecimenReviewRequiredLabelRule(message: "specimen review needs an entry"),
                SpecimenReviewDescriptionLengthRule(maxLength: 1000),
                SpecimenReviewAllowedCodeRule(allowed: ["batched"]),
            ]
        )
    }
}
