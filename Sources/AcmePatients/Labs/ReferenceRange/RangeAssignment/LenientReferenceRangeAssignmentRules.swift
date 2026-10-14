import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient reference range assignment must pass. Check returns its problems, or none.
    protocol LenientReferenceRangeAssignmentRule {
        func check(_ item: LenientReferenceRangeAssignment) -> [String]
    }

    final class LenientReferenceRangeAssignmentCodePrefixRule: LenientReferenceRangeAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientReferenceRangeAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientReferenceRangeAssignmentLabelLengthRule: LenientReferenceRangeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientReferenceRangeAssignment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientReferenceRangeAssignmentWeightRangeRule: LenientReferenceRangeAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientReferenceRangeAssignment) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientReferenceRangeAssignmentRequiredLabelRule: LenientReferenceRangeAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReferenceRangeAssignment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientReferenceRangeAssignmentCapacityRangeRule: LenientReferenceRangeAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientReferenceRangeAssignment) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientReferenceRangeAssignmentPatientRefLengthRule: LenientReferenceRangeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientReferenceRangeAssignment) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient reference range assignment.
    final class LenientReferenceRangeAssignmentValidator {
        var rules: [any LenientReferenceRangeAssignmentRule]

        init(rules: [any LenientReferenceRangeAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientReferenceRangeAssignment) -> [String] {
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

        func requireValid(_ item: LenientReferenceRangeAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientReferenceRangeAssignment]) -> [String: [String]] {
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

    static func defaultLenientReferenceRangeAssignmentValidator() -> LenientReferenceRangeAssignmentValidator {
        return LenientReferenceRangeAssignmentValidator(
            rules: [
                LenientReferenceRangeAssignmentCodePrefixRule(prefix: "REF"),
                LenientReferenceRangeAssignmentLabelLengthRule(maxLength: 120),
                LenientReferenceRangeAssignmentWeightRangeRule(min: 8.7, max: 1809.2),
                LenientReferenceRangeAssignmentRequiredLabelRule(
                    message: "lenient reference range assignment needs an entry"
                ),
                LenientReferenceRangeAssignmentCapacityRangeRule(min: 80, max: 3600),
                LenientReferenceRangeAssignmentPatientRefLengthRule(maxLength: 64),
            ]
        )
    }
}
