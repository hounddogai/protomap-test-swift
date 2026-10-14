import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff allocation must pass. Check returns its problems, or none.
    protocol HandoffAllocationRule {
        func check(_ item: HandoffAllocation) -> [String]
    }

    final class HandoffAllocationLabelLengthRule: HandoffAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffAllocation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffAllocationCodePrefixRule: HandoffAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: HandoffAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class HandoffAllocationCodeLengthRule: HandoffAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffAllocationVisitMinutesRangeRule: HandoffAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffAllocation) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff allocation.
    final class HandoffAllocationValidator {
        var rules: [any HandoffAllocationRule]

        init(rules: [any HandoffAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffAllocation) -> [String] {
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

        func requireValid(_ item: HandoffAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffAllocation]) -> [String: [String]] {
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

    static func defaultHandoffAllocationValidator() -> HandoffAllocationValidator {
        return HandoffAllocationValidator(
            rules: [
                HandoffAllocationLabelLengthRule(maxLength: 255),
                HandoffAllocationCodePrefixRule(prefix: "Q"),
                HandoffAllocationCodeLengthRule(maxLength: 3600),
                HandoffAllocationVisitMinutesRangeRule(min: 16, max: 64),
            ]
        )
    }
}
