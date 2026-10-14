import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched remittance target must pass. Check returns its problems, or none.
    protocol BatchedRemittanceTargetRule {
        func check(_ item: BatchedRemittanceTarget) -> [String]
    }

    final class BatchedRemittanceTargetEndsAtRangeRule: BatchedRemittanceTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedRemittanceTarget) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedRemittanceTargetAllowedCodeRule: BatchedRemittanceTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedRemittanceTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class BatchedRemittanceTargetCodePrefixRule: BatchedRemittanceTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedRemittanceTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched remittance target.
    final class BatchedRemittanceTargetValidator {
        var rules: [any BatchedRemittanceTargetRule]

        init(rules: [any BatchedRemittanceTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedRemittanceTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedRemittanceTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedRemittanceTarget]) -> [String: [String]] {
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

    static func defaultBatchedRemittanceTargetValidator() -> BatchedRemittanceTargetValidator {
        return BatchedRemittanceTargetValidator(
            rules: [
                BatchedRemittanceTargetEndsAtRangeRule(min: 16, max: 16),
                BatchedRemittanceTargetAllowedCodeRule(allowed: ["pending", "capped"]),
                BatchedRemittanceTargetCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
