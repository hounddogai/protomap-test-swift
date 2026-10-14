import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped modality assignment must pass. Check returns its problems, or none.
    protocol CappedModalityAssignmentRule {
        func check(_ item: CappedModalityAssignment) -> [String]
    }

    final class CappedModalityAssignmentTitleLengthRule: CappedModalityAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedModalityAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedModalityAssignmentRequiredCodeRule: CappedModalityAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedModalityAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedModalityAssignmentStartsAtRangeRule: CappedModalityAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedModalityAssignment) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped modality assignment.
    final class CappedModalityAssignmentValidator {
        var rules: [any CappedModalityAssignmentRule]

        init(rules: [any CappedModalityAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedModalityAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedModalityAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedModalityAssignment]) -> [String: [String]] {
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

    static func defaultCappedModalityAssignmentValidator() -> CappedModalityAssignmentValidator {
        return CappedModalityAssignmentValidator(
            rules: [
                CappedModalityAssignmentTitleLengthRule(maxLength: 1000),
                CappedModalityAssignmentRequiredCodeRule(message: "capped modality assignment needs this field"),
                CappedModalityAssignmentStartsAtRangeRule(min: 64, max: 3600),
            ]
        )
    }
}
