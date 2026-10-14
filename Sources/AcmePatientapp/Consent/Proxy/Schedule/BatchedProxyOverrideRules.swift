import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched proxy override must pass. Check returns its problems, or none.
    protocol BatchedProxyOverrideRule {
        func check(_ item: BatchedProxyOverride) -> [String]
    }

    final class BatchedProxyOverrideDosageMgRangeRule: BatchedProxyOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedProxyOverride) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedProxyOverrideCodeLengthRule: BatchedProxyOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProxyOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedProxyOverrideAllowedExternalRefRule: BatchedProxyOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedProxyOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a batched proxy override.
    final class BatchedProxyOverrideValidator {
        var rules: [any BatchedProxyOverrideRule]

        init(rules: [any BatchedProxyOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedProxyOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedProxyOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedProxyOverride]) -> [String: [String]] {
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

    static func defaultBatchedProxyOverrideValidator() -> BatchedProxyOverrideValidator {
        return BatchedProxyOverrideValidator(
            rules: [
                BatchedProxyOverrideDosageMgRangeRule(min: 3.1, max: 230.7),
                BatchedProxyOverrideCodeLengthRule(maxLength: 3600),
                BatchedProxyOverrideAllowedExternalRefRule(allowed: ["lenient"]),
            ]
        )
    }
}
