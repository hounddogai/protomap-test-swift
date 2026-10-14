import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped formulary review must pass. Check returns its problems, or none.
    protocol CappedFormularyReviewRule {
        func check(_ item: CappedFormularyReview) -> [String]
    }

    final class CappedFormularyReviewAllowedDiagnosisCodeRule: CappedFormularyReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedFormularyReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is blocked"]
            }
            return []
        }
    }

    final class CappedFormularyReviewCodePrefixRule: CappedFormularyReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedFormularyReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedFormularyReviewTitleLengthRule: CappedFormularyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedFormularyReview) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedFormularyReviewRequiredTitleRule: CappedFormularyReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedFormularyReview) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedFormularyReviewDiagnosisCodeLengthRule: CappedFormularyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedFormularyReview) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped formulary review.
    final class CappedFormularyReviewValidator {
        var rules: [any CappedFormularyReviewRule]

        init(rules: [any CappedFormularyReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedFormularyReview) -> [String] {
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

        func requireValid(_ item: CappedFormularyReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedFormularyReview]) -> [String: [String]] {
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

    static func defaultCappedFormularyReviewValidator() -> CappedFormularyReviewValidator {
        return CappedFormularyReviewValidator(
            rules: [
                CappedFormularyReviewAllowedDiagnosisCodeRule(allowed: ["default", "lenient"]),
                CappedFormularyReviewCodePrefixRule(prefix: "Q"),
                CappedFormularyReviewTitleLengthRule(maxLength: 16),
                CappedFormularyReviewRequiredTitleRule(message: "capped formulary review needs this field"),
                CappedFormularyReviewDiagnosisCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
