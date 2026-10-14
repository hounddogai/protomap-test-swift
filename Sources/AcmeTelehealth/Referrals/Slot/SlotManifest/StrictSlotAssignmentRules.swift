import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a strict slot assignment must pass. Check returns its problems, or none.
    protocol StrictSlotAssignmentRule {
        func check(_ item: StrictSlotAssignment) -> [String]
    }

    final class StrictSlotAssignmentRequiredNotesRule: StrictSlotAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSlotAssignment) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSlotAssignmentPatientRefLengthRule: StrictSlotAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSlotAssignment) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictSlotAssignmentNotesLengthRule: StrictSlotAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSlotAssignment) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictSlotAssignmentRequiredNameRule: StrictSlotAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictSlotAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictSlotAssignmentAllowedCodeRule: StrictSlotAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictSlotAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class StrictSlotAssignmentCodeLengthRule: StrictSlotAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictSlotAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict slot assignment.
    final class StrictSlotAssignmentValidator {
        var rules: [any StrictSlotAssignmentRule]

        init(rules: [any StrictSlotAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictSlotAssignment) -> [String] {
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

        func requireValid(_ item: StrictSlotAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictSlotAssignment]) -> [String: [String]] {
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

    static func defaultStrictSlotAssignmentValidator() -> StrictSlotAssignmentValidator {
        return StrictSlotAssignmentValidator(
            rules: [
                StrictSlotAssignmentRequiredNotesRule(message: "strict slot assignment needs an entry"),
                StrictSlotAssignmentPatientRefLengthRule(maxLength: 255),
                StrictSlotAssignmentNotesLengthRule(maxLength: 16),
                StrictSlotAssignmentRequiredNameRule(message: "strict slot assignment needs an entry"),
                StrictSlotAssignmentAllowedCodeRule(allowed: []),
                StrictSlotAssignmentCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
