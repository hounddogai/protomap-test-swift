import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional assessment window must pass. Check returns its problems, or none.
    protocol RegionalAssessmentWindowRule {
        func check(_ item: RegionalAssessmentWindow) -> [String]
    }

    final class RegionalAssessmentWindowRequiredPhoneRule: RegionalAssessmentWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAssessmentWindow) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalAssessmentWindowUpdatedAtRangeRule: RegionalAssessmentWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAssessmentWindow) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalAssessmentWindowCopayRangeRule: RegionalAssessmentWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAssessmentWindow) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalAssessmentWindowRequiredSpecialtyRule: RegionalAssessmentWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAssessmentWindow) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalAssessmentWindowSpecialtyLengthRule: RegionalAssessmentWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAssessmentWindow) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalAssessmentWindowAllowedContactEmailRule: RegionalAssessmentWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalAssessmentWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a regional assessment window.
    final class RegionalAssessmentWindowValidator {
        var rules: [any RegionalAssessmentWindowRule]

        init(rules: [any RegionalAssessmentWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalAssessmentWindow) -> [String] {
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

        func requireValid(_ item: RegionalAssessmentWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalAssessmentWindow]) -> [String: [String]] {
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

    static func defaultRegionalAssessmentWindowValidator() -> RegionalAssessmentWindowValidator {
        return RegionalAssessmentWindowValidator(
            rules: [
                RegionalAssessmentWindowRequiredPhoneRule(message: "regional assessment window needs a value"),
                RegionalAssessmentWindowUpdatedAtRangeRule(min: 16, max: 255),
                RegionalAssessmentWindowCopayRangeRule(min: 7.8, max: 4380.2),
                RegionalAssessmentWindowRequiredSpecialtyRule(message: "regional assessment window needs an entry"),
                RegionalAssessmentWindowSpecialtyLengthRule(maxLength: 3600),
                RegionalAssessmentWindowAllowedContactEmailRule(allowed: ["default", "scheduled", "strict"]),
            ]
        )
    }
}
