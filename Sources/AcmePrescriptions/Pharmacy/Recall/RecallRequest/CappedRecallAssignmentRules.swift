import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a capped recall assignment must pass. Check returns its problems, or none.
    protocol CappedRecallAssignmentRule {
        func check(_ item: CappedRecallAssignment) -> [String]
    }

    final class CappedRecallAssignmentRequiredOwnerIDRule: CappedRecallAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRecallAssignment) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedRecallAssignmentTitleLengthRule: CappedRecallAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedRecallAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedRecallAssignmentRequiredTitleRule: CappedRecallAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedRecallAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped recall assignment.
    final class CappedRecallAssignmentValidator {
        var rules: [any CappedRecallAssignmentRule]

        init(rules: [any CappedRecallAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedRecallAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedRecallAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedRecallAssignment]) -> [String: [String]] {
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

    static func defaultCappedRecallAssignmentValidator() -> CappedRecallAssignmentValidator {
        return CappedRecallAssignmentValidator(
            rules: [
                CappedRecallAssignmentRequiredOwnerIDRule(message: "capped recall assignment needs this field"),
                CappedRecallAssignmentTitleLengthRule(maxLength: 32),
                CappedRecallAssignmentRequiredTitleRule(message: "capped recall assignment needs this field"),
            ]
        )
    }
}
