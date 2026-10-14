import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback assessment assignment must pass. Check returns its problems, or none.
    protocol FallbackAssessmentAssignmentRule {
        func check(_ item: FallbackAssessmentAssignment) -> [String]
    }

    final class FallbackAssessmentAssignmentCodePrefixRule: FallbackAssessmentAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackAssessmentAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackAssessmentAssignmentWeightRangeRule: FallbackAssessmentAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackAssessmentAssignment) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackAssessmentAssignmentRatioRangeRule: FallbackAssessmentAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackAssessmentAssignment) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackAssessmentAssignmentCodeLengthRule: FallbackAssessmentAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAssessmentAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAssessmentAssignmentRequiredTitleRule: FallbackAssessmentAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAssessmentAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAssessmentAssignmentAllowedCodeRule: FallbackAssessmentAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackAssessmentAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback assessment assignment.
    final class FallbackAssessmentAssignmentValidator {
        var rules: [any FallbackAssessmentAssignmentRule]

        init(rules: [any FallbackAssessmentAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackAssessmentAssignment) -> [String] {
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

        func requireValid(_ item: FallbackAssessmentAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackAssessmentAssignment]) -> [String: [String]] {
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

    static func defaultFallbackAssessmentAssignmentValidator() -> FallbackAssessmentAssignmentValidator {
        return FallbackAssessmentAssignmentValidator(
            rules: [
                FallbackAssessmentAssignmentCodePrefixRule(prefix: "X"),
                FallbackAssessmentAssignmentWeightRangeRule(min: 7.0, max: 3718.1),
                FallbackAssessmentAssignmentRatioRangeRule(min: 7.5, max: 1269.1),
                FallbackAssessmentAssignmentCodeLengthRule(maxLength: 86400),
                FallbackAssessmentAssignmentRequiredTitleRule(
                    message: "fallback assessment assignment needs this field"
                ),
                FallbackAssessmentAssignmentAllowedCodeRule(allowed: []),
            ]
        )
    }
}
