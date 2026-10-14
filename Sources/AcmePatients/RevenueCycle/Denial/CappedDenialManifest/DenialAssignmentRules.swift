import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial assignment must pass. Check returns its problems, or none.
    protocol DenialAssignmentRule {
        func check(_ item: DenialAssignment) -> [String]
    }

    final class DenialAssignmentLabelLengthRule: DenialAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialAssignment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialAssignmentCodeLengthRule: DenialAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialAssignmentAllowedContactEmailRule: DenialAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DenialAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is too long"]
            }
            return []
        }
    }

    final class DenialAssignmentRequiredLabelRule: DenialAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialAssignment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a denial assignment.
    final class DenialAssignmentValidator {
        var rules: [any DenialAssignmentRule]

        init(rules: [any DenialAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialAssignment]) -> [String: [String]] {
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

    static func defaultDenialAssignmentValidator() -> DenialAssignmentValidator {
        return DenialAssignmentValidator(
            rules: [
                DenialAssignmentLabelLengthRule(maxLength: 1000),
                DenialAssignmentCodeLengthRule(maxLength: 64),
                DenialAssignmentAllowedContactEmailRule(allowed: []),
                DenialAssignmentRequiredLabelRule(message: "denial assignment needs a value"),
            ]
        )
    }
}
