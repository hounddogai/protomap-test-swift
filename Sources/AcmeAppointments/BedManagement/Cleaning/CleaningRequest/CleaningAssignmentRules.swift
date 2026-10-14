import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning assignment must pass. Check returns its problems, or none.
    protocol CleaningAssignmentRule {
        func check(_ item: CleaningAssignment) -> [String]
    }

    final class CleaningAssignmentRegionLengthRule: CleaningAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningAssignment) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningAssignmentRequiredRegionRule: CleaningAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningAssignment) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningAssignmentRequiredNameRule: CleaningAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning assignment.
    final class CleaningAssignmentValidator {
        var rules: [any CleaningAssignmentRule]

        init(rules: [any CleaningAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningAssignment) -> [String] {
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

        func requireValid(_ item: CleaningAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningAssignment]) -> [String: [String]] {
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

    static func defaultCleaningAssignmentValidator() -> CleaningAssignmentValidator {
        return CleaningAssignmentValidator(
            rules: [
                CleaningAssignmentRegionLengthRule(maxLength: 1000),
                CleaningAssignmentRequiredRegionRule(message: "cleaning assignment needs this field"),
                CleaningAssignmentRequiredNameRule(message: "cleaning assignment needs this field"),
            ]
        )
    }
}
