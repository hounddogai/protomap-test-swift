import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read milestone must pass. Check returns its problems, or none.
    protocol ReadMilestoneRule {
        func check(_ item: ReadMilestone) -> [String]
    }

    final class ReadMilestoneRequiredSpecialtyRule: ReadMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadMilestone) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadMilestoneCodeLengthRule: ReadMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadMilestoneAttemptsRangeRule: ReadMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadMilestone) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a read milestone.
    final class ReadMilestoneValidator {
        var rules: [any ReadMilestoneRule]

        init(rules: [any ReadMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadMilestone]) -> [String: [String]] {
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

    static func defaultReadMilestoneValidator() -> ReadMilestoneValidator {
        return ReadMilestoneValidator(
            rules: [
                ReadMilestoneRequiredSpecialtyRule(message: "read milestone needs this field"),
                ReadMilestoneCodeLengthRule(maxLength: 86400),
                ReadMilestoneAttemptsRangeRule(min: 16, max: 3600),
            ]
        )
    }
}
