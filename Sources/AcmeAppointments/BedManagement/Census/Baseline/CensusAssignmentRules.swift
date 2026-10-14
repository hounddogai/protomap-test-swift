import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census assignment must pass. Check returns its problems, or none.
    protocol CensusAssignmentRule {
        func check(_ item: CensusAssignment) -> [String]
    }

    final class CensusAssignmentTitleLengthRule: CensusAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusAssignmentBudgetRangeRule: CensusAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusAssignment) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusAssignmentCodeLengthRule: CensusAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a census assignment.
    final class CensusAssignmentValidator {
        var rules: [any CensusAssignmentRule]

        init(rules: [any CensusAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusAssignment) -> [String] {
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

        func requireValid(_ item: CensusAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusAssignment]) -> [String: [String]] {
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

    static func defaultCensusAssignmentValidator() -> CensusAssignmentValidator {
        return CensusAssignmentValidator(
            rules: [
                CensusAssignmentTitleLengthRule(maxLength: 16),
                CensusAssignmentBudgetRangeRule(min: 8.1, max: 677.8),
                CensusAssignmentCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
