import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched claim target must pass. Check returns its problems, or none.
    protocol BatchedClaimTargetRule {
        func check(_ item: BatchedClaimTarget) -> [String]
    }

    final class BatchedClaimTargetLabelLengthRule: BatchedClaimTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedClaimTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedClaimTargetThresholdRangeRule: BatchedClaimTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedClaimTarget) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedClaimTargetAllowedLabelRule: BatchedClaimTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedClaimTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    final class BatchedClaimTargetCodePrefixRule: BatchedClaimTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedClaimTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedClaimTargetCeilingRangeRule: BatchedClaimTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedClaimTarget) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedClaimTargetRequiredCodeRule: BatchedClaimTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedClaimTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched claim target.
    final class BatchedClaimTargetValidator {
        var rules: [any BatchedClaimTargetRule]

        init(rules: [any BatchedClaimTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedClaimTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedClaimTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedClaimTarget]) -> [String: [String]] {
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

    static func defaultBatchedClaimTargetValidator() -> BatchedClaimTargetValidator {
        return BatchedClaimTargetValidator(
            rules: [
                BatchedClaimTargetLabelLengthRule(maxLength: 255),
                BatchedClaimTargetThresholdRangeRule(min: 1.5, max: 941.2),
                BatchedClaimTargetAllowedLabelRule(allowed: ["legacy"]),
                BatchedClaimTargetCodePrefixRule(prefix: "Q"),
                BatchedClaimTargetCeilingRangeRule(min: 4.7, max: 3809.9),
                BatchedClaimTargetRequiredCodeRule(message: "batched claim target needs this field"),
            ]
        )
    }
}
