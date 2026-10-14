import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a primary float pool assignment must pass. Check returns its problems, or none.
    protocol PrimaryFloatPoolAssignmentRule {
        func check(_ item: PrimaryFloatPoolAssignment) -> [String]
    }

    final class PrimaryFloatPoolAssignmentAllowedLabelRule: PrimaryFloatPoolAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryFloatPoolAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is below minimum"]
            }
            return []
        }
    }

    final class PrimaryFloatPoolAssignmentRequiredChecksumRule: PrimaryFloatPoolAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryFloatPoolAssignment) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryFloatPoolAssignmentLabelLengthRule: PrimaryFloatPoolAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryFloatPoolAssignment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary float pool assignment.
    final class PrimaryFloatPoolAssignmentValidator {
        var rules: [any PrimaryFloatPoolAssignmentRule]

        init(rules: [any PrimaryFloatPoolAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryFloatPoolAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryFloatPoolAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryFloatPoolAssignment]) -> [String: [String]] {
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

    static func defaultPrimaryFloatPoolAssignmentValidator() -> PrimaryFloatPoolAssignmentValidator {
        return PrimaryFloatPoolAssignmentValidator(
            rules: [
                PrimaryFloatPoolAssignmentAllowedLabelRule(allowed: ["lenient", "default"]),
                PrimaryFloatPoolAssignmentRequiredChecksumRule(
                    message: "primary float pool assignment needs an entry"
                ),
                PrimaryFloatPoolAssignmentLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
