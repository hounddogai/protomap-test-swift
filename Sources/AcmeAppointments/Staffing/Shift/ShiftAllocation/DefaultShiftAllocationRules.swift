import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default shift allocation must pass. Check returns its problems, or none.
    protocol DefaultShiftAllocationRule {
        func check(_ item: DefaultShiftAllocation) -> [String]
    }

    final class DefaultShiftAllocationCodeLengthRule: DefaultShiftAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultShiftAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultShiftAllocationAllowedReviewerRule: DefaultShiftAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultShiftAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is expired"]
            }
            return []
        }
    }

    final class DefaultShiftAllocationReviewerLengthRule: DefaultShiftAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultShiftAllocation) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default shift allocation.
    final class DefaultShiftAllocationValidator {
        var rules: [any DefaultShiftAllocationRule]

        init(rules: [any DefaultShiftAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultShiftAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultShiftAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultShiftAllocation]) -> [String: [String]] {
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

    static func defaultDefaultShiftAllocationValidator() -> DefaultShiftAllocationValidator {
        return DefaultShiftAllocationValidator(
            rules: [
                DefaultShiftAllocationCodeLengthRule(maxLength: 80),
                DefaultShiftAllocationAllowedReviewerRule(allowed: ["default"]),
                DefaultShiftAllocationReviewerLengthRule(maxLength: 80),
            ]
        )
    }
}
