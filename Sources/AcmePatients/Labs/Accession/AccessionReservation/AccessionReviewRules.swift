import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession review must pass. Check returns its problems, or none.
    protocol AccessionReviewRule {
        func check(_ item: AccessionReview) -> [String]
    }

    final class AccessionReviewRegionLengthRule: AccessionReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionReview) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionReviewRequiredLocaleRule: AccessionReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionReview) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionReviewNameLengthRule: AccessionReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession review.
    final class AccessionReviewValidator {
        var rules: [any AccessionReviewRule]

        init(rules: [any AccessionReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionReview]) -> [String: [String]] {
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

    static func defaultAccessionReviewValidator() -> AccessionReviewValidator {
        return AccessionReviewValidator(
            rules: [
                AccessionReviewRegionLengthRule(maxLength: 16),
                AccessionReviewRequiredLocaleRule(message: "accession review needs a value"),
                AccessionReviewNameLengthRule(maxLength: 80),
            ]
        )
    }
}
