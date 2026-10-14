import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive dispense review must pass. Check returns its problems, or none.
    protocol AdaptiveDispenseReviewRule {
        func check(_ item: AdaptiveDispenseReview) -> [String]
    }

    final class AdaptiveDispenseReviewCodeLengthRule: AdaptiveDispenseReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDispenseReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveDispenseReviewRequiredEncounterIDRule: AdaptiveDispenseReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveDispenseReview) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveDispenseReviewEncounterIDLengthRule: AdaptiveDispenseReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveDispenseReview) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive dispense review.
    final class AdaptiveDispenseReviewValidator {
        var rules: [any AdaptiveDispenseReviewRule]

        init(rules: [any AdaptiveDispenseReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveDispenseReview) -> [String] {
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

        func requireValid(_ item: AdaptiveDispenseReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveDispenseReview]) -> [String: [String]] {
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

    static func defaultAdaptiveDispenseReviewValidator() -> AdaptiveDispenseReviewValidator {
        return AdaptiveDispenseReviewValidator(
            rules: [
                AdaptiveDispenseReviewCodeLengthRule(maxLength: 86400),
                AdaptiveDispenseReviewRequiredEncounterIDRule(message: "adaptive dispense review needs this field"),
                AdaptiveDispenseReviewEncounterIDLengthRule(maxLength: 1000),
            ]
        )
    }
}
