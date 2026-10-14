import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert allocation must pass. Check returns its problems, or none.
    protocol AlertAllocationRule {
        func check(_ item: AlertAllocation) -> [String]
    }

    final class AlertAllocationReviewerLengthRule: AlertAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertAllocation) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertAllocationPriorityRangeRule: AlertAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertAllocation) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AlertAllocationAllowedReviewerRule: AlertAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AlertAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a alert allocation.
    final class AlertAllocationValidator {
        var rules: [any AlertAllocationRule]

        init(rules: [any AlertAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertAllocation) -> [String] {
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

        func requireValid(_ item: AlertAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertAllocation]) -> [String: [String]] {
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

    static func defaultAlertAllocationValidator() -> AlertAllocationValidator {
        return AlertAllocationValidator(
            rules: [
                AlertAllocationReviewerLengthRule(maxLength: 80),
                AlertAllocationPriorityRangeRule(min: 32, max: 255),
                AlertAllocationAllowedReviewerRule(allowed: []),
            ]
        )
    }
}
