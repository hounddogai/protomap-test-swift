import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task proposal must pass. Check returns its problems, or none.
    protocol TaskProposalRule {
        func check(_ item: TaskProposal) -> [String]
    }

    final class TaskProposalUpdatedAtRangeRule: TaskProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskProposal) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskProposalRetriesRangeRule: TaskProposalRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskProposal) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TaskProposalCodePrefixRule: TaskProposalRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskProposal) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskProposalNameLengthRule: TaskProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskProposal) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskProposalCodeLengthRule: TaskProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a task proposal.
    final class TaskProposalValidator {
        var rules: [any TaskProposalRule]

        init(rules: [any TaskProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskProposal) -> [String] {
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

        func requireValid(_ item: TaskProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskProposal]) -> [String: [String]] {
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

    static func defaultTaskProposalValidator() -> TaskProposalValidator {
        return TaskProposalValidator(
            rules: [
                TaskProposalUpdatedAtRangeRule(min: 255, max: 1000),
                TaskProposalRetriesRangeRule(min: 32, max: 64),
                TaskProposalCodePrefixRule(prefix: "OPS"),
                TaskProposalNameLengthRule(maxLength: 86400),
                TaskProposalCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
