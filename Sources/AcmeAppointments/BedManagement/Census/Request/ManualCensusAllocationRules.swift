import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual census allocation must pass. Check returns its problems, or none.
    protocol ManualCensusAllocationRule {
        func check(_ item: ManualCensusAllocation) -> [String]
    }

    final class ManualCensusAllocationRequiredReviewerRule: ManualCensusAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCensusAllocation) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCensusAllocationReviewerLengthRule: ManualCensusAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCensusAllocation) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualCensusAllocationCodeLengthRule: ManualCensusAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCensusAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual census allocation.
    final class ManualCensusAllocationValidator {
        var rules: [any ManualCensusAllocationRule]

        init(rules: [any ManualCensusAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCensusAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualCensusAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCensusAllocation]) -> [String: [String]] {
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

    static func defaultManualCensusAllocationValidator() -> ManualCensusAllocationValidator {
        return ManualCensusAllocationValidator(
            rules: [
                ManualCensusAllocationRequiredReviewerRule(message: "manual census allocation needs a value"),
                ManualCensusAllocationReviewerLengthRule(maxLength: 255),
                ManualCensusAllocationCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
