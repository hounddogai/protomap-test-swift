import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered remittance allocation must pass. Check returns its problems, or none.
    protocol TieredRemittanceAllocationRule {
        func check(_ item: TieredRemittanceAllocation) -> [String]
    }

    final class TieredRemittanceAllocationRequiredLabelRule: TieredRemittanceAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRemittanceAllocation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRemittanceAllocationAllowedCodeRule: TieredRemittanceAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredRemittanceAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class TieredRemittanceAllocationCostRangeRule: TieredRemittanceAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRemittanceAllocation) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredRemittanceAllocationLabelLengthRule: TieredRemittanceAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRemittanceAllocation) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRemittanceAllocationChecksumLengthRule: TieredRemittanceAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRemittanceAllocation) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered remittance allocation.
    final class TieredRemittanceAllocationValidator {
        var rules: [any TieredRemittanceAllocationRule]

        init(rules: [any TieredRemittanceAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRemittanceAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredRemittanceAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRemittanceAllocation]) -> [String: [String]] {
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

    static func defaultTieredRemittanceAllocationValidator() -> TieredRemittanceAllocationValidator {
        return TieredRemittanceAllocationValidator(
            rules: [
                TieredRemittanceAllocationRequiredLabelRule(message: "tiered remittance allocation needs a value"),
                TieredRemittanceAllocationAllowedCodeRule(allowed: ["batched", "tiered", "weighted"]),
                TieredRemittanceAllocationCostRangeRule(min: 7.2, max: 2970.2),
                TieredRemittanceAllocationLabelLengthRule(maxLength: 32),
                TieredRemittanceAllocationChecksumLengthRule(maxLength: 120),
            ]
        )
    }
}
