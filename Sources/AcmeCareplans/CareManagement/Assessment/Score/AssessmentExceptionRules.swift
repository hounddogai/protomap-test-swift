import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment exception must pass. Check returns its problems, or none.
    protocol AssessmentExceptionRule {
        func check(_ item: AssessmentException) -> [String]
    }

    final class AssessmentExceptionFloorValueRangeRule: AssessmentExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentException) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AssessmentExceptionCodeLengthRule: AssessmentExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentExceptionRequiredSegmentRule: AssessmentExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentException) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentExceptionSegmentLengthRule: AssessmentExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentException) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentExceptionReviewerLengthRule: AssessmentExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentException) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentExceptionRatioRangeRule: AssessmentExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentException) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment exception.
    final class AssessmentExceptionValidator {
        var rules: [any AssessmentExceptionRule]

        init(rules: [any AssessmentExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentException) -> [String] {
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

        func requireValid(_ item: AssessmentException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentException]) -> [String: [String]] {
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

    static func defaultAssessmentExceptionValidator() -> AssessmentExceptionValidator {
        return AssessmentExceptionValidator(
            rules: [
                AssessmentExceptionFloorValueRangeRule(min: 0.6, max: 147.0),
                AssessmentExceptionCodeLengthRule(maxLength: 32),
                AssessmentExceptionRequiredSegmentRule(message: "assessment exception needs an entry"),
                AssessmentExceptionSegmentLengthRule(maxLength: 120),
                AssessmentExceptionReviewerLengthRule(maxLength: 80),
                AssessmentExceptionRatioRangeRule(min: 8.5, max: 1674.6),
            ]
        )
    }
}
