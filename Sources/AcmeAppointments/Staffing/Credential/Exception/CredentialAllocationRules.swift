import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential allocation must pass. Check returns its problems, or none.
    protocol CredentialAllocationRule {
        func check(_ item: CredentialAllocation) -> [String]
    }

    final class CredentialAllocationRefillsRangeRule: CredentialAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialAllocation) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CredentialAllocationPriorityRangeRule: CredentialAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialAllocation) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialAllocationCodePrefixRule: CredentialAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CredentialAllocationWeightRangeRule: CredentialAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialAllocation) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CredentialAllocationReviewerLengthRule: CredentialAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialAllocation) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential allocation.
    final class CredentialAllocationValidator {
        var rules: [any CredentialAllocationRule]

        init(rules: [any CredentialAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialAllocation]) -> [String: [String]] {
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

    static func defaultCredentialAllocationValidator() -> CredentialAllocationValidator {
        return CredentialAllocationValidator(
            rules: [
                CredentialAllocationRefillsRangeRule(min: 1000, max: 86400),
                CredentialAllocationPriorityRangeRule(min: 32, max: 64),
                CredentialAllocationCodePrefixRule(prefix: "OPS"),
                CredentialAllocationWeightRangeRule(min: 8.3, max: 2614.7),
                CredentialAllocationReviewerLengthRule(maxLength: 86400),
            ]
        )
    }
}
