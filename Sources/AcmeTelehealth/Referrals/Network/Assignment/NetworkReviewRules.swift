import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network review must pass. Check returns its problems, or none.
    protocol NetworkReviewRule {
        func check(_ item: NetworkReview) -> [String]
    }

    final class NetworkReviewRequiredDescriptionRule: NetworkReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkReview) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkReviewRequiredNameRule: NetworkReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkReviewCodeLengthRule: NetworkReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network review.
    final class NetworkReviewValidator {
        var rules: [any NetworkReviewRule]

        init(rules: [any NetworkReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkReview) -> [String] {
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

        func requireValid(_ item: NetworkReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkReview]) -> [String: [String]] {
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

    static func defaultNetworkReviewValidator() -> NetworkReviewValidator {
        return NetworkReviewValidator(
            rules: [
                NetworkReviewRequiredDescriptionRule(message: "network review needs an entry"),
                NetworkReviewRequiredNameRule(message: "network review needs a value"),
                NetworkReviewCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
