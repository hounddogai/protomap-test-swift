import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional reference range profile must pass. Check returns its problems, or none.
    protocol RegionalReferenceRangeProfileRule {
        func check(_ item: RegionalReferenceRangeProfile) -> [String]
    }

    final class RegionalReferenceRangeProfileDurationMinutesRangeRule: RegionalReferenceRangeProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalReferenceRangeProfile) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalReferenceRangeProfileLabelLengthRule: RegionalReferenceRangeProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalReferenceRangeProfile) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalReferenceRangeProfileReviewerLengthRule: RegionalReferenceRangeProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalReferenceRangeProfile) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalReferenceRangeProfileRequiredProcedureCodeRule: RegionalReferenceRangeProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalReferenceRangeProfile) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalReferenceRangeProfileRevisionRangeRule: RegionalReferenceRangeProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalReferenceRangeProfile) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalReferenceRangeProfileRequiredReviewerRule: RegionalReferenceRangeProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalReferenceRangeProfile) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional reference range profile.
    final class RegionalReferenceRangeProfileValidator {
        var rules: [any RegionalReferenceRangeProfileRule]

        init(rules: [any RegionalReferenceRangeProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalReferenceRangeProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalReferenceRangeProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalReferenceRangeProfile]) -> [String: [String]] {
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

    static func defaultRegionalReferenceRangeProfileValidator() -> RegionalReferenceRangeProfileValidator {
        return RegionalReferenceRangeProfileValidator(
            rules: [
                RegionalReferenceRangeProfileDurationMinutesRangeRule(min: 3600, max: 86400),
                RegionalReferenceRangeProfileLabelLengthRule(maxLength: 64),
                RegionalReferenceRangeProfileReviewerLengthRule(maxLength: 255),
                RegionalReferenceRangeProfileRequiredProcedureCodeRule(
                    message: "regional reference range profile needs a value"
                ),
                RegionalReferenceRangeProfileRevisionRangeRule(min: 3600, max: 86400),
                RegionalReferenceRangeProfileRequiredReviewerRule(
                    message: "regional reference range profile needs this field"
                ),
            ]
        )
    }
}
