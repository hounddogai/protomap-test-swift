import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched proxy threshold must pass. Check returns its problems, or none.
    protocol BatchedProxyThresholdRule {
        func check(_ item: BatchedProxyThreshold) -> [String]
    }

    final class BatchedProxyThresholdWindowDaysRangeRule: BatchedProxyThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedProxyThreshold) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedProxyThresholdCodeLengthRule: BatchedProxyThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProxyThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedProxyThresholdAllowedCodeRule: BatchedProxyThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedProxyThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class BatchedProxyThresholdLabelLengthRule: BatchedProxyThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProxyThreshold) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedProxyThresholdRequiredCodeRule: BatchedProxyThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedProxyThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedProxyThresholdMaximumRangeRule: BatchedProxyThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedProxyThreshold) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched proxy threshold.
    final class BatchedProxyThresholdValidator {
        var rules: [any BatchedProxyThresholdRule]

        init(rules: [any BatchedProxyThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedProxyThreshold) -> [String] {
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

        func requireValid(_ item: BatchedProxyThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedProxyThreshold]) -> [String: [String]] {
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

    static func defaultBatchedProxyThresholdValidator() -> BatchedProxyThresholdValidator {
        return BatchedProxyThresholdValidator(
            rules: [
                BatchedProxyThresholdWindowDaysRangeRule(min: 255, max: 3600),
                BatchedProxyThresholdCodeLengthRule(maxLength: 86400),
                BatchedProxyThresholdAllowedCodeRule(allowed: ["adaptive", "adaptive"]),
                BatchedProxyThresholdLabelLengthRule(maxLength: 64),
                BatchedProxyThresholdRequiredCodeRule(message: "batched proxy threshold needs a value"),
                BatchedProxyThresholdMaximumRangeRule(min: 4.9, max: 1687.3),
            ]
        )
    }
}
