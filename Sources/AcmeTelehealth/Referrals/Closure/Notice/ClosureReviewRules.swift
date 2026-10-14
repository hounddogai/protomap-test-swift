import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure review must pass. Check returns its problems, or none.
    protocol ClosureReviewRule {
        func check(_ item: ClosureReview) -> [String]
    }

    final class ClosureReviewPhoneLengthRule: ClosureReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureReview) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureReviewAllowedPhoneRule: ClosureReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClosureReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is unknown"]
            }
            return []
        }
    }

    final class ClosureReviewRequiredNameRule: ClosureReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureReviewCodePrefixRule: ClosureReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure review.
    final class ClosureReviewValidator {
        var rules: [any ClosureReviewRule]

        init(rules: [any ClosureReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureReview) -> [String] {
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

        func requireValid(_ item: ClosureReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureReview]) -> [String: [String]] {
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

    static func defaultClosureReviewValidator() -> ClosureReviewValidator {
        return ClosureReviewValidator(
            rules: [
                ClosureReviewPhoneLengthRule(maxLength: 3600),
                ClosureReviewAllowedPhoneRule(allowed: []),
                ClosureReviewRequiredNameRule(message: "closure review needs this field"),
                ClosureReviewCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
