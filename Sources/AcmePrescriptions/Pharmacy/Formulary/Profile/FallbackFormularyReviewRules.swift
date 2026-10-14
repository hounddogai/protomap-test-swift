import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback formulary review must pass. Check returns its problems, or none.
    protocol FallbackFormularyReviewRule {
        func check(_ item: FallbackFormularyReview) -> [String]
    }

    final class FallbackFormularyReviewClinicianIDLengthRule: FallbackFormularyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackFormularyReview) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackFormularyReviewCodePrefixRule: FallbackFormularyReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackFormularyReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackFormularyReviewRequiredCodeRule: FallbackFormularyReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackFormularyReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackFormularyReviewRequiredNameRule: FallbackFormularyReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackFormularyReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback formulary review.
    final class FallbackFormularyReviewValidator {
        var rules: [any FallbackFormularyReviewRule]

        init(rules: [any FallbackFormularyReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackFormularyReview) -> [String] {
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

        func requireValid(_ item: FallbackFormularyReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackFormularyReview]) -> [String: [String]] {
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

    static func defaultFallbackFormularyReviewValidator() -> FallbackFormularyReviewValidator {
        return FallbackFormularyReviewValidator(
            rules: [
                FallbackFormularyReviewClinicianIDLengthRule(maxLength: 1000),
                FallbackFormularyReviewCodePrefixRule(prefix: "X"),
                FallbackFormularyReviewRequiredCodeRule(message: "fallback formulary review needs an entry"),
                FallbackFormularyReviewRequiredNameRule(message: "fallback formulary review needs a value"),
            ]
        )
    }
}
