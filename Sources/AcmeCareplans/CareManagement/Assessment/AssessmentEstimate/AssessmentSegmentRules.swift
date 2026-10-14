import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment segment must pass. Check returns its problems, or none.
    protocol AssessmentSegmentRule {
        func check(_ item: AssessmentSegment) -> [String]
    }

    final class AssessmentSegmentLabelLengthRule: AssessmentSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentSegmentArchivedGuardRule: AssessmentSegmentRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: AssessmentSegment) -> [String] {
            if item.archived && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class AssessmentSegmentMaximumRangeRule: AssessmentSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentSegment) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AssessmentSegmentRequiredLabelRule: AssessmentSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentSegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentSegmentClinicianIDLengthRule: AssessmentSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentSegment) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentSegmentCodePrefixRule: AssessmentSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AssessmentSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment segment.
    final class AssessmentSegmentValidator {
        var rules: [any AssessmentSegmentRule]

        init(rules: [any AssessmentSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentSegment) -> [String] {
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

        func requireValid(_ item: AssessmentSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentSegment]) -> [String: [String]] {
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

    static func defaultAssessmentSegmentValidator() -> AssessmentSegmentValidator {
        return AssessmentSegmentValidator(
            rules: [
                AssessmentSegmentLabelLengthRule(maxLength: 86400),
                AssessmentSegmentArchivedGuardRule(limit: 5.5),
                AssessmentSegmentMaximumRangeRule(min: 7.8, max: 2905.9),
                AssessmentSegmentRequiredLabelRule(message: "assessment segment needs an entry"),
                AssessmentSegmentClinicianIDLengthRule(maxLength: 64),
                AssessmentSegmentCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
