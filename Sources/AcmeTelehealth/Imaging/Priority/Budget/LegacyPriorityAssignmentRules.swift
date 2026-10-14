import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy priority assignment must pass. Check returns its problems, or none.
    protocol LegacyPriorityAssignmentRule {
        func check(_ item: LegacyPriorityAssignment) -> [String]
    }

    final class LegacyPriorityAssignmentCodeLengthRule: LegacyPriorityAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyPriorityAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyPriorityAssignmentUnitLengthRule: LegacyPriorityAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyPriorityAssignment) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyPriorityAssignmentPinnedGuardRule: LegacyPriorityAssignmentRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LegacyPriorityAssignment) -> [String] {
            if item.pinned && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy priority assignment.
    final class LegacyPriorityAssignmentValidator {
        var rules: [any LegacyPriorityAssignmentRule]

        init(rules: [any LegacyPriorityAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyPriorityAssignment) -> [String] {
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

        func requireValid(_ item: LegacyPriorityAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyPriorityAssignment]) -> [String: [String]] {
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

    static func defaultLegacyPriorityAssignmentValidator() -> LegacyPriorityAssignmentValidator {
        return LegacyPriorityAssignmentValidator(
            rules: [
                LegacyPriorityAssignmentCodeLengthRule(maxLength: 3600),
                LegacyPriorityAssignmentUnitLengthRule(maxLength: 64),
                LegacyPriorityAssignmentPinnedGuardRule(limit: 1.5),
            ]
        )
    }
}
