import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read assignment must pass. Check returns its problems, or none.
    protocol ReadAssignmentRule {
        func check(_ item: ReadAssignment) -> [String]
    }

    final class ReadAssignmentTimezoneLengthRule: ReadAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadAssignment) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadAssignmentPatientRefLengthRule: ReadAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadAssignment) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadAssignmentRequiredCodeRule: ReadAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a read assignment.
    final class ReadAssignmentValidator {
        var rules: [any ReadAssignmentRule]

        init(rules: [any ReadAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadAssignment]) -> [String: [String]] {
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

    static func defaultReadAssignmentValidator() -> ReadAssignmentValidator {
        return ReadAssignmentValidator(
            rules: [
                ReadAssignmentTimezoneLengthRule(maxLength: 1000),
                ReadAssignmentPatientRefLengthRule(maxLength: 80),
                ReadAssignmentRequiredCodeRule(message: "read assignment needs this field"),
            ]
        )
    }
}
