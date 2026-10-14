import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback care protocol assignment must pass. Check returns its problems, or none.
    protocol FallbackCareProtocolAssignmentRule {
        func check(_ item: FallbackCareProtocolAssignment) -> [String]
    }

    final class FallbackCareProtocolAssignmentEndsAtRangeRule: FallbackCareProtocolAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCareProtocolAssignment) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackCareProtocolAssignmentLabelLengthRule: FallbackCareProtocolAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareProtocolAssignment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolAssignmentRequiredCodeRule: FallbackCareProtocolAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCareProtocolAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback care protocol assignment.
    final class FallbackCareProtocolAssignmentValidator {
        var rules: [any FallbackCareProtocolAssignmentRule]

        init(rules: [any FallbackCareProtocolAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCareProtocolAssignment) -> [String] {
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

        func requireValid(_ item: FallbackCareProtocolAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCareProtocolAssignment]) -> [String: [String]] {
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

    static func defaultFallbackCareProtocolAssignmentValidator() -> FallbackCareProtocolAssignmentValidator {
        return FallbackCareProtocolAssignmentValidator(
            rules: [
                FallbackCareProtocolAssignmentEndsAtRangeRule(min: 80, max: 3600),
                FallbackCareProtocolAssignmentLabelLengthRule(maxLength: 86400),
                FallbackCareProtocolAssignmentRequiredCodeRule(
                    message: "fallback care protocol assignment needs an entry"
                ),
            ]
        )
    }
}
