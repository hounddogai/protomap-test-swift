import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped reference range allocation must pass. Check returns its problems, or none.
    protocol CappedReferenceRangeAllocationRule {
        func check(_ item: CappedReferenceRangeAllocation) -> [String]
    }

    final class CappedReferenceRangeAllocationAllowedCodeRule: CappedReferenceRangeAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedReferenceRangeAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class CappedReferenceRangeAllocationStartsAtRangeRule: CappedReferenceRangeAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedReferenceRangeAllocation) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedReferenceRangeAllocationCodeLengthRule: CappedReferenceRangeAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedReferenceRangeAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedReferenceRangeAllocationCodePrefixRule: CappedReferenceRangeAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedReferenceRangeAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped reference range allocation.
    final class CappedReferenceRangeAllocationValidator {
        var rules: [any CappedReferenceRangeAllocationRule]

        init(rules: [any CappedReferenceRangeAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedReferenceRangeAllocation) -> [String] {
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

        func requireValid(_ item: CappedReferenceRangeAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedReferenceRangeAllocation]) -> [String: [String]] {
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

    static func defaultCappedReferenceRangeAllocationValidator() -> CappedReferenceRangeAllocationValidator {
        return CappedReferenceRangeAllocationValidator(
            rules: [
                CappedReferenceRangeAllocationAllowedCodeRule(allowed: ["batched", "regional"]),
                CappedReferenceRangeAllocationStartsAtRangeRule(min: 32, max: 32),
                CappedReferenceRangeAllocationCodeLengthRule(maxLength: 16),
                CappedReferenceRangeAllocationCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
