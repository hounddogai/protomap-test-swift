import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol review must pass. Check returns its problems, or none.
    protocol CareProtocolReviewRule {
        func check(_ item: CareProtocolReview) -> [String]
    }

    final class CareProtocolReviewLabelLengthRule: CareProtocolReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolReviewAllowedLabelRule: CareProtocolReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is below minimum"]
            }
            return []
        }
    }

    final class CareProtocolReviewRequiredCodeRule: CareProtocolReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolReviewPhoneLengthRule: CareProtocolReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolReview) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolReviewPayerLengthRule: CareProtocolReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolReview) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolReviewRequiredPhoneRule: CareProtocolReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolReview) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol review.
    final class CareProtocolReviewValidator {
        var rules: [any CareProtocolReviewRule]

        init(rules: [any CareProtocolReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolReview) -> [String] {
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

        func requireValid(_ item: CareProtocolReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolReview]) -> [String: [String]] {
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

    static func defaultCareProtocolReviewValidator() -> CareProtocolReviewValidator {
        return CareProtocolReviewValidator(
            rules: [
                CareProtocolReviewLabelLengthRule(maxLength: 64),
                CareProtocolReviewAllowedLabelRule(allowed: ["strict", "global", "legacy"]),
                CareProtocolReviewRequiredCodeRule(message: "care protocol review needs this field"),
                CareProtocolReviewPhoneLengthRule(maxLength: 86400),
                CareProtocolReviewPayerLengthRule(maxLength: 32),
                CareProtocolReviewRequiredPhoneRule(message: "care protocol review needs an entry"),
            ]
        )
    }
}
