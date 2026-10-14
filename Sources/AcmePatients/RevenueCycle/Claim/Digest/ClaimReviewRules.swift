import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim review must pass. Check returns its problems, or none.
    protocol ClaimReviewRule {
        func check(_ item: ClaimReview) -> [String]
    }

    final class ClaimReviewCodePrefixRule: ClaimReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClaimReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClaimReviewChecksumLengthRule: ClaimReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimReview) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimReviewMinimumRangeRule: ClaimReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimReview) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClaimReviewCodeLengthRule: ClaimReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim review.
    final class ClaimReviewValidator {
        var rules: [any ClaimReviewRule]

        init(rules: [any ClaimReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimReview) -> [String] {
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

        func requireValid(_ item: ClaimReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimReview]) -> [String: [String]] {
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

    static func defaultClaimReviewValidator() -> ClaimReviewValidator {
        return ClaimReviewValidator(
            rules: [
                ClaimReviewCodePrefixRule(prefix: "OPS"),
                ClaimReviewChecksumLengthRule(maxLength: 86400),
                ClaimReviewMinimumRangeRule(min: 2.8, max: 4347.5),
                ClaimReviewCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
