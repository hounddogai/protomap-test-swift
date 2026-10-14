import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure review must pass. Check returns its problems, or none.
    protocol DisclosureReviewRule {
        func check(_ item: DisclosureReview) -> [String]
    }

    final class DisclosureReviewCodeLengthRule: DisclosureReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureReviewRequiredContactEmailRule: DisclosureReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureReview) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureReviewCodePrefixRule: DisclosureReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DisclosureReviewRequiredLabelRule: DisclosureReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureReviewSequenceRangeRule: DisclosureReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureReview) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DisclosureReviewPhoneLengthRule: DisclosureReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureReview) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure review.
    final class DisclosureReviewValidator {
        var rules: [any DisclosureReviewRule]

        init(rules: [any DisclosureReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureReview]) -> [String: [String]] {
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

    static func defaultDisclosureReviewValidator() -> DisclosureReviewValidator {
        return DisclosureReviewValidator(
            rules: [
                DisclosureReviewCodeLengthRule(maxLength: 32),
                DisclosureReviewRequiredContactEmailRule(message: "disclosure review needs a value"),
                DisclosureReviewCodePrefixRule(prefix: "OPS"),
                DisclosureReviewRequiredLabelRule(message: "disclosure review needs a value"),
                DisclosureReviewSequenceRangeRule(min: 1000, max: 3600),
                DisclosureReviewPhoneLengthRule(maxLength: 80),
            ]
        )
    }
}
