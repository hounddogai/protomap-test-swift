import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback alert assignment must pass. Check returns its problems, or none.
    protocol FallbackAlertAssignmentRule {
        func check(_ item: FallbackAlertAssignment) -> [String]
    }

    final class FallbackAlertAssignmentFacilityLengthRule: FallbackAlertAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAlertAssignment) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAlertAssignmentCodeLengthRule: FallbackAlertAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAlertAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAlertAssignmentNameLengthRule: FallbackAlertAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAlertAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAlertAssignmentRequiredNameRule: FallbackAlertAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAlertAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAlertAssignmentRequiredFacilityRule: FallbackAlertAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAlertAssignment) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAlertAssignmentRequiredTitleRule: FallbackAlertAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAlertAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback alert assignment.
    final class FallbackAlertAssignmentValidator {
        var rules: [any FallbackAlertAssignmentRule]

        init(rules: [any FallbackAlertAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackAlertAssignment) -> [String] {
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

        func requireValid(_ item: FallbackAlertAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackAlertAssignment]) -> [String: [String]] {
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

    static func defaultFallbackAlertAssignmentValidator() -> FallbackAlertAssignmentValidator {
        return FallbackAlertAssignmentValidator(
            rules: [
                FallbackAlertAssignmentFacilityLengthRule(maxLength: 80),
                FallbackAlertAssignmentCodeLengthRule(maxLength: 120),
                FallbackAlertAssignmentNameLengthRule(maxLength: 255),
                FallbackAlertAssignmentRequiredNameRule(message: "fallback alert assignment needs an entry"),
                FallbackAlertAssignmentRequiredFacilityRule(message: "fallback alert assignment needs this field"),
                FallbackAlertAssignmentRequiredTitleRule(message: "fallback alert assignment needs an entry"),
            ]
        )
    }
}
