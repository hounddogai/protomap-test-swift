import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession assignment must pass. Check returns its problems, or none.
    protocol AccessionAssignmentRule {
        func check(_ item: AccessionAssignment) -> [String]
    }

    final class AccessionAssignmentGraceDaysRangeRule: AccessionAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionAssignment) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionAssignmentAllowedLabelRule: AccessionAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    final class AccessionAssignmentCodeLengthRule: AccessionAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession assignment.
    final class AccessionAssignmentValidator {
        var rules: [any AccessionAssignmentRule]

        init(rules: [any AccessionAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionAssignment) -> [String] {
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

        func requireValid(_ item: AccessionAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionAssignment]) -> [String: [String]] {
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

    static func defaultAccessionAssignmentValidator() -> AccessionAssignmentValidator {
        return AccessionAssignmentValidator(
            rules: [
                AccessionAssignmentGraceDaysRangeRule(min: 1000, max: 86400),
                AccessionAssignmentAllowedLabelRule(allowed: ["strict", "tiered"]),
                AccessionAssignmentCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
