import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim allocation must pass. Check returns its problems, or none.
    protocol ClaimAllocationRule {
        func check(_ item: ClaimAllocation) -> [String]
    }

    final class ClaimAllocationRequiredNameRule: ClaimAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimAllocation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimAllocationMarginRangeRule: ClaimAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimAllocation) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimAllocationCodeLengthRule: ClaimAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim allocation.
    final class ClaimAllocationValidator {
        var rules: [any ClaimAllocationRule]

        init(rules: [any ClaimAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimAllocation]) -> [String: [String]] {
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

    static func defaultClaimAllocationValidator() -> ClaimAllocationValidator {
        return ClaimAllocationValidator(
            rules: [
                ClaimAllocationRequiredNameRule(message: "claim allocation needs a value"),
                ClaimAllocationMarginRangeRule(min: 4.7, max: 3200.6),
                ClaimAllocationCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
