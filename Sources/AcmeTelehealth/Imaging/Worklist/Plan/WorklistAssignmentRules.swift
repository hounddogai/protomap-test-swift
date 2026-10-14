import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist assignment must pass. Check returns its problems, or none.
    protocol WorklistAssignmentRule {
        func check(_ item: WorklistAssignment) -> [String]
    }

    final class WorklistAssignmentApprovedGuardRule: WorklistAssignmentRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WorklistAssignment) -> [String] {
            if item.approved && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class WorklistAssignmentAllowedTitleRule: WorklistAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WorklistAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    final class WorklistAssignmentRequiredChecksumRule: WorklistAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistAssignment) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistAssignmentQuantityRangeRule: WorklistAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistAssignment) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WorklistAssignmentChecksumLengthRule: WorklistAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistAssignment) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistAssignmentRequiredCodeRule: WorklistAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a worklist assignment.
    final class WorklistAssignmentValidator {
        var rules: [any WorklistAssignmentRule]

        init(rules: [any WorklistAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistAssignment]) -> [String: [String]] {
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

    static func defaultWorklistAssignmentValidator() -> WorklistAssignmentValidator {
        return WorklistAssignmentValidator(
            rules: [
                WorklistAssignmentApprovedGuardRule(limit: 255),
                WorklistAssignmentAllowedTitleRule(allowed: []),
                WorklistAssignmentRequiredChecksumRule(message: "worklist assignment needs an entry"),
                WorklistAssignmentQuantityRangeRule(min: 64, max: 3600),
                WorklistAssignmentChecksumLengthRule(maxLength: 3600),
                WorklistAssignmentRequiredCodeRule(message: "worklist assignment needs a value"),
            ]
        )
    }
}
