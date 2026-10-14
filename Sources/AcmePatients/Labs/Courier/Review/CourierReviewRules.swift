import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier review must pass. Check returns its problems, or none.
    protocol CourierReviewRule {
        func check(_ item: CourierReview) -> [String]
    }

    final class CourierReviewRequiredUnitRule: CourierReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierReview) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierReviewRequiredCodeRule: CourierReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierReviewRequiredNameRule: CourierReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a courier review.
    final class CourierReviewValidator {
        var rules: [any CourierReviewRule]

        init(rules: [any CourierReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierReview) -> [String] {
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

        func requireValid(_ item: CourierReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierReview]) -> [String: [String]] {
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

    static func defaultCourierReviewValidator() -> CourierReviewValidator {
        return CourierReviewValidator(
            rules: [
                CourierReviewRequiredUnitRule(message: "courier review needs an entry"),
                CourierReviewRequiredCodeRule(message: "courier review needs this field"),
                CourierReviewRequiredNameRule(message: "courier review needs an entry"),
            ]
        )
    }
}
