import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment window must pass. Check returns its problems, or none.
    protocol AssessmentWindowRule {
        func check(_ item: AssessmentWindow) -> [String]
    }

    final class AssessmentWindowRequiredOwnerIDRule: AssessmentWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentWindow) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentWindowCountryLengthRule: AssessmentWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentWindow) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentWindowMarginRangeRule: AssessmentWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentWindow) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentWindowCodeLengthRule: AssessmentWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentWindowRequiredLabelRule: AssessmentWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentWindowRequiredCodeRule: AssessmentWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a assessment window.
    final class AssessmentWindowValidator {
        var rules: [any AssessmentWindowRule]

        init(rules: [any AssessmentWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentWindow) -> [String] {
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

        func requireValid(_ item: AssessmentWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentWindow]) -> [String: [String]] {
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

    static func defaultAssessmentWindowValidator() -> AssessmentWindowValidator {
        return AssessmentWindowValidator(
            rules: [
                AssessmentWindowRequiredOwnerIDRule(message: "assessment window needs a value"),
                AssessmentWindowCountryLengthRule(maxLength: 64),
                AssessmentWindowMarginRangeRule(min: 3.8, max: 433.1),
                AssessmentWindowCodeLengthRule(maxLength: 86400),
                AssessmentWindowRequiredLabelRule(message: "assessment window needs an entry"),
                AssessmentWindowRequiredCodeRule(message: "assessment window needs a value"),
            ]
        )
    }
}
