import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation assignment must pass. Check returns its problems, or none.
    protocol RevocationAssignmentRule {
        func check(_ item: RevocationAssignment) -> [String]
    }

    final class RevocationAssignmentFacilityLengthRule: RevocationAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationAssignment) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationAssignmentRequiredNameRule: RevocationAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationAssignment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationAssignmentNameLengthRule: RevocationAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationAssignment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation assignment.
    final class RevocationAssignmentValidator {
        var rules: [any RevocationAssignmentRule]

        init(rules: [any RevocationAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationAssignment]) -> [String: [String]] {
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

    static func defaultRevocationAssignmentValidator() -> RevocationAssignmentValidator {
        return RevocationAssignmentValidator(
            rules: [
                RevocationAssignmentFacilityLengthRule(maxLength: 86400),
                RevocationAssignmentRequiredNameRule(message: "revocation assignment needs this field"),
                RevocationAssignmentNameLengthRule(maxLength: 1000),
            ]
        )
    }
}
