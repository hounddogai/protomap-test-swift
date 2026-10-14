import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form review must pass. Check returns its problems, or none.
    protocol ConsentFormReviewRule {
        func check(_ item: ConsentFormReview) -> [String]
    }

    final class ConsentFormReviewCodeLengthRule: ConsentFormReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormReviewPatientRefLengthRule: ConsentFormReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormReview) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormReviewRequiredCodeRule: ConsentFormReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormReviewApprovedGuardRule: ConsentFormReviewRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ConsentFormReview) -> [String] {
            if item.approved && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ConsentFormReviewCodePrefixRule: ConsentFormReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ConsentFormReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ConsentFormReviewLabelLengthRule: ConsentFormReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form review.
    final class ConsentFormReviewValidator {
        var rules: [any ConsentFormReviewRule]

        init(rules: [any ConsentFormReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormReview) -> [String] {
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

        func requireValid(_ item: ConsentFormReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormReview]) -> [String: [String]] {
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

    static func defaultConsentFormReviewValidator() -> ConsentFormReviewValidator {
        return ConsentFormReviewValidator(
            rules: [
                ConsentFormReviewCodeLengthRule(maxLength: 1000),
                ConsentFormReviewPatientRefLengthRule(maxLength: 1000),
                ConsentFormReviewRequiredCodeRule(message: "consent form review needs a value"),
                ConsentFormReviewApprovedGuardRule(limit: 1000),
                ConsentFormReviewCodePrefixRule(prefix: "ACM"),
                ConsentFormReviewLabelLengthRule(maxLength: 86400),
            ]
        )
    }
}
