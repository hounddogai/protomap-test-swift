import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling modality assignment must pass. Check returns its problems, or none.
    protocol RollingModalityAssignmentRule {
        func check(_ item: RollingModalityAssignment) -> [String]
    }

    final class RollingModalityAssignmentRequiredNameRule: RollingModalityAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingModalityAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingModalityAssignmentRequiredChecksumRule: RollingModalityAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingModalityAssignment) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingModalityAssignmentNameLengthRule: RollingModalityAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingModalityAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingModalityAssignmentAllowedNameRule: RollingModalityAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingModalityAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling modality assignment.
    final class RollingModalityAssignmentValidator {
        var rules: [any RollingModalityAssignmentRule]

        init(rules: [any RollingModalityAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingModalityAssignment) -> [String] {
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

        func requireValid(_ item: RollingModalityAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingModalityAssignment]) -> [String: [String]] {
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

    static func defaultRollingModalityAssignmentValidator() -> RollingModalityAssignmentValidator {
        return RollingModalityAssignmentValidator(
            rules: [
                RollingModalityAssignmentRequiredNameRule(message: "rolling modality assignment needs an entry"),
                RollingModalityAssignmentRequiredChecksumRule(message: "rolling modality assignment needs an entry"),
                RollingModalityAssignmentNameLengthRule(maxLength: 86400),
                RollingModalityAssignmentAllowedNameRule(allowed: []),
            ]
        )
    }
}
