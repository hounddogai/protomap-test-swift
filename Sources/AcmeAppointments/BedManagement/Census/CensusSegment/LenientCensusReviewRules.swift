import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient census review must pass. Check returns its problems, or none.
    protocol LenientCensusReviewRule {
        func check(_ item: LenientCensusReview) -> [String]
    }

    final class LenientCensusReviewCountryLengthRule: LenientCensusReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCensusReview) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCensusReviewRequiredCountryRule: LenientCensusReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCensusReview) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCensusReviewRetriesRangeRule: LenientCensusReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCensusReview) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientCensusReviewCodeLengthRule: LenientCensusReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCensusReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient census review.
    final class LenientCensusReviewValidator {
        var rules: [any LenientCensusReviewRule]

        init(rules: [any LenientCensusReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCensusReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientCensusReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCensusReview]) -> [String: [String]] {
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

    static func defaultLenientCensusReviewValidator() -> LenientCensusReviewValidator {
        return LenientCensusReviewValidator(
            rules: [
                LenientCensusReviewCountryLengthRule(maxLength: 1000),
                LenientCensusReviewRequiredCountryRule(message: "lenient census review needs an entry"),
                LenientCensusReviewRetriesRangeRule(min: 16, max: 80),
                LenientCensusReviewCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
