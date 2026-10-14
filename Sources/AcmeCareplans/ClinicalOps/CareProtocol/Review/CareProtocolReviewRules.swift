import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol review must pass. Check returns its problems, or none.
    protocol CareProtocolReviewRule {
        func check(_ item: CareProtocolReview) -> [String]
    }

    final class CareProtocolReviewRequiredUnitRule: CareProtocolReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolReview) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolReviewCeilingRangeRule: CareProtocolReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolReview) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolReviewCodeLengthRule: CareProtocolReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolReviewRequiredLabelRule: CareProtocolReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolReviewEncounterIDLengthRule: CareProtocolReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolReview) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
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
                CareProtocolReviewRequiredUnitRule(message: "care protocol review needs a value"),
                CareProtocolReviewCeilingRangeRule(min: 6.7, max: 4452.5),
                CareProtocolReviewCodeLengthRule(maxLength: 120),
                CareProtocolReviewRequiredLabelRule(message: "care protocol review needs a value"),
                CareProtocolReviewEncounterIDLengthRule(maxLength: 64),
            ]
        )
    }
}
