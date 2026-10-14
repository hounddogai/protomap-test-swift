import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched denial target must pass. Check returns its problems, or none.
    protocol BatchedDenialTargetRule {
        func check(_ item: BatchedDenialTarget) -> [String]
    }

    final class BatchedDenialTargetAllowedCodeRule: BatchedDenialTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedDenialTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class BatchedDenialTargetCodePrefixRule: BatchedDenialTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedDenialTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedDenialTargetLimitRangeRule: BatchedDenialTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDenialTarget) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedDenialTargetNameLengthRule: BatchedDenialTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDenialTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched denial target.
    final class BatchedDenialTargetValidator {
        var rules: [any BatchedDenialTargetRule]

        init(rules: [any BatchedDenialTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDenialTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedDenialTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDenialTarget]) -> [String: [String]] {
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

    static func defaultBatchedDenialTargetValidator() -> BatchedDenialTargetValidator {
        return BatchedDenialTargetValidator(
            rules: [
                BatchedDenialTargetAllowedCodeRule(allowed: ["regional", "global"]),
                BatchedDenialTargetCodePrefixRule(prefix: "Q"),
                BatchedDenialTargetLimitRangeRule(min: 86400, max: 86400),
                BatchedDenialTargetNameLengthRule(maxLength: 120),
            ]
        )
    }
}
