import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending reference range allocation must pass. Check returns its problems, or none.
    protocol PendingReferenceRangeAllocationRule {
        func check(_ item: PendingReferenceRangeAllocation) -> [String]
    }

    final class PendingReferenceRangeAllocationRequiredCodeRule: PendingReferenceRangeAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReferenceRangeAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReferenceRangeAllocationRequiredLocaleRule: PendingReferenceRangeAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReferenceRangeAllocation) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReferenceRangeAllocationSummaryLengthRule: PendingReferenceRangeAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReferenceRangeAllocation) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReferenceRangeAllocationCeilingRangeRule: PendingReferenceRangeAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingReferenceRangeAllocation) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a pending reference range allocation.
    final class PendingReferenceRangeAllocationValidator {
        var rules: [any PendingReferenceRangeAllocationRule]

        init(rules: [any PendingReferenceRangeAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingReferenceRangeAllocation) -> [String] {
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

        func requireValid(_ item: PendingReferenceRangeAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingReferenceRangeAllocation]) -> [String: [String]] {
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

    static func defaultPendingReferenceRangeAllocationValidator() -> PendingReferenceRangeAllocationValidator {
        return PendingReferenceRangeAllocationValidator(
            rules: [
                PendingReferenceRangeAllocationRequiredCodeRule(
                    message: "pending reference range allocation needs a value"
                ),
                PendingReferenceRangeAllocationRequiredLocaleRule(
                    message: "pending reference range allocation needs a value"
                ),
                PendingReferenceRangeAllocationSummaryLengthRule(maxLength: 1000),
                PendingReferenceRangeAllocationCeilingRangeRule(min: 4.7, max: 1774.6),
            ]
        )
    }
}
