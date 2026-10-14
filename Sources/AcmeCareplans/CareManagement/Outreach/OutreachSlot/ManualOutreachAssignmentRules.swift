import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual outreach assignment must pass. Check returns its problems, or none.
    protocol ManualOutreachAssignmentRule {
        func check(_ item: ManualOutreachAssignment) -> [String]
    }

    final class ManualOutreachAssignmentNameLengthRule: ManualOutreachAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualOutreachAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualOutreachAssignmentLabelLengthRule: ManualOutreachAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualOutreachAssignment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualOutreachAssignmentAllowedLabelRule: ManualOutreachAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualOutreachAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    final class ManualOutreachAssignmentRequiredNameRule: ManualOutreachAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualOutreachAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualOutreachAssignmentCodeLengthRule: ManualOutreachAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualOutreachAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual outreach assignment.
    final class ManualOutreachAssignmentValidator {
        var rules: [any ManualOutreachAssignmentRule]

        init(rules: [any ManualOutreachAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualOutreachAssignment) -> [String] {
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

        func requireValid(_ item: ManualOutreachAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualOutreachAssignment]) -> [String: [String]] {
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

    static func defaultManualOutreachAssignmentValidator() -> ManualOutreachAssignmentValidator {
        return ManualOutreachAssignmentValidator(
            rules: [
                ManualOutreachAssignmentNameLengthRule(maxLength: 64),
                ManualOutreachAssignmentLabelLengthRule(maxLength: 3600),
                ManualOutreachAssignmentAllowedLabelRule(allowed: ["weighted", "seasonal", "tiered"]),
                ManualOutreachAssignmentRequiredNameRule(message: "manual outreach assignment needs an entry"),
                ManualOutreachAssignmentCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
