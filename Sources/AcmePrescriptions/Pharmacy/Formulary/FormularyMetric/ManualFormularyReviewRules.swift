import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual formulary review must pass. Check returns its problems, or none.
    protocol ManualFormularyReviewRule {
        func check(_ item: ManualFormularyReview) -> [String]
    }

    final class ManualFormularyReviewDescriptionLengthRule: ManualFormularyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualFormularyReview) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualFormularyReviewPatientRefLengthRule: ManualFormularyReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualFormularyReview) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualFormularyReviewFloorValueRangeRule: ManualFormularyReviewRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualFormularyReview) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualFormularyReviewExpiresAtRangeRule: ManualFormularyReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualFormularyReview) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualFormularyReviewCodePrefixRule: ManualFormularyReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualFormularyReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualFormularyReviewRequiredPatientRefRule: ManualFormularyReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualFormularyReview) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual formulary review.
    final class ManualFormularyReviewValidator {
        var rules: [any ManualFormularyReviewRule]

        init(rules: [any ManualFormularyReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualFormularyReview) -> [String] {
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

        func requireValid(_ item: ManualFormularyReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualFormularyReview]) -> [String: [String]] {
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

    static func defaultManualFormularyReviewValidator() -> ManualFormularyReviewValidator {
        return ManualFormularyReviewValidator(
            rules: [
                ManualFormularyReviewDescriptionLengthRule(maxLength: 16),
                ManualFormularyReviewPatientRefLengthRule(maxLength: 120),
                ManualFormularyReviewFloorValueRangeRule(min: 8.8, max: 820.7),
                ManualFormularyReviewExpiresAtRangeRule(min: 80, max: 120),
                ManualFormularyReviewCodePrefixRule(prefix: "ACM"),
                ManualFormularyReviewRequiredPatientRefRule(message: "manual formulary review needs this field"),
            ]
        )
    }
}
