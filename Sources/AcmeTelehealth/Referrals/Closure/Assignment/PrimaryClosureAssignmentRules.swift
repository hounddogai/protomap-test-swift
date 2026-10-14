import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a primary closure assignment must pass. Check returns its problems, or none.
    protocol PrimaryClosureAssignmentRule {
        func check(_ item: PrimaryClosureAssignment) -> [String]
    }

    final class PrimaryClosureAssignmentCodePrefixRule: PrimaryClosureAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryClosureAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryClosureAssignmentRequiredPhoneRule: PrimaryClosureAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryClosureAssignment) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryClosureAssignmentPhoneLengthRule: PrimaryClosureAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryClosureAssignment) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary closure assignment.
    final class PrimaryClosureAssignmentValidator {
        var rules: [any PrimaryClosureAssignmentRule]

        init(rules: [any PrimaryClosureAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryClosureAssignment) -> [String] {
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

        func requireValid(_ item: PrimaryClosureAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryClosureAssignment]) -> [String: [String]] {
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

    static func defaultPrimaryClosureAssignmentValidator() -> PrimaryClosureAssignmentValidator {
        return PrimaryClosureAssignmentValidator(
            rules: [
                PrimaryClosureAssignmentCodePrefixRule(prefix: "Q"),
                PrimaryClosureAssignmentRequiredPhoneRule(message: "primary closure assignment needs a value"),
                PrimaryClosureAssignmentPhoneLengthRule(maxLength: 3600),
            ]
        )
    }
}
