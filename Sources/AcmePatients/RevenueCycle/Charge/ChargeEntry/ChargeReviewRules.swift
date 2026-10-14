import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge review must pass. Check returns its problems, or none.
    protocol ChargeReviewRule {
        func check(_ item: ChargeReview) -> [String]
    }

    final class ChargeReviewSegmentLengthRule: ChargeReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeReview) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeReviewAllowedNameRule: ChargeReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ChargeReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    final class ChargeReviewRequiredCodeRule: ChargeReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeReviewRequiredNameRule: ChargeReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeReviewNameLengthRule: ChargeReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeReviewSummaryLengthRule: ChargeReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeReview) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge review.
    final class ChargeReviewValidator {
        var rules: [any ChargeReviewRule]

        init(rules: [any ChargeReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeReview]) -> [String: [String]] {
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

    static func defaultChargeReviewValidator() -> ChargeReviewValidator {
        return ChargeReviewValidator(
            rules: [
                ChargeReviewSegmentLengthRule(maxLength: 1000),
                ChargeReviewAllowedNameRule(allowed: ["pending", "default", "scheduled"]),
                ChargeReviewRequiredCodeRule(message: "charge review needs a value"),
                ChargeReviewRequiredNameRule(message: "charge review needs a value"),
                ChargeReviewNameLengthRule(maxLength: 120),
                ChargeReviewSummaryLengthRule(maxLength: 64),
            ]
        )
    }
}
