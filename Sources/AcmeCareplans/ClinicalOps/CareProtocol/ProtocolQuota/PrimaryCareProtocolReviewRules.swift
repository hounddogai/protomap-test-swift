import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary care protocol review must pass. Check returns its problems, or none.
    protocol PrimaryCareProtocolReviewRule {
        func check(_ item: PrimaryCareProtocolReview) -> [String]
    }

    final class PrimaryCareProtocolReviewCodeLengthRule: PrimaryCareProtocolReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCareProtocolReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCareProtocolReviewRequiredTitleRule: PrimaryCareProtocolReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCareProtocolReview) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCareProtocolReviewAcuityRangeRule: PrimaryCareProtocolReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCareProtocolReview) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryCareProtocolReviewAllowedCodeRule: PrimaryCareProtocolReviewRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryCareProtocolReview) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class PrimaryCareProtocolReviewRequiredChecksumRule: PrimaryCareProtocolReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCareProtocolReview) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary care protocol review.
    final class PrimaryCareProtocolReviewValidator {
        var rules: [any PrimaryCareProtocolReviewRule]

        init(rules: [any PrimaryCareProtocolReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCareProtocolReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryCareProtocolReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCareProtocolReview]) -> [String: [String]] {
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

    static func defaultPrimaryCareProtocolReviewValidator() -> PrimaryCareProtocolReviewValidator {
        return PrimaryCareProtocolReviewValidator(
            rules: [
                PrimaryCareProtocolReviewCodeLengthRule(maxLength: 80),
                PrimaryCareProtocolReviewRequiredTitleRule(message: "primary care protocol review needs an entry"),
                PrimaryCareProtocolReviewAcuityRangeRule(min: 120, max: 86400),
                PrimaryCareProtocolReviewAllowedCodeRule(allowed: []),
                PrimaryCareProtocolReviewRequiredChecksumRule(message: "primary care protocol review needs an entry"),
            ]
        )
    }
}
