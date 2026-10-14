import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime review must pass. Check returns its problems, or none.
    protocol OvertimeReviewRule {
        func check(_ item: OvertimeReview) -> [String]
    }

    final class OvertimeReviewTitleLengthRule: OvertimeReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeReview) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeReviewCodePrefixRule: OvertimeReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OvertimeReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OvertimeReviewRequiredNameRule: OvertimeReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime review.
    final class OvertimeReviewValidator {
        var rules: [any OvertimeReviewRule]

        init(rules: [any OvertimeReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeReview) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OvertimeReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeReview]) -> [String: [String]] {
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

    static func defaultOvertimeReviewValidator() -> OvertimeReviewValidator {
        return OvertimeReviewValidator(
            rules: [
                OvertimeReviewTitleLengthRule(maxLength: 64),
                OvertimeReviewCodePrefixRule(prefix: "OPS"),
                OvertimeReviewRequiredNameRule(message: "overtime review needs an entry"),
            ]
        )
    }
}
