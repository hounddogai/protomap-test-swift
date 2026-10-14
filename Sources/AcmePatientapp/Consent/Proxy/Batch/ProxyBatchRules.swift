import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy batch must pass. Check returns its problems, or none.
    protocol ProxyBatchRule {
        func check(_ item: ProxyBatch) -> [String]
    }

    final class ProxyBatchCodeLengthRule: ProxyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyBatchCodePrefixRule: ProxyBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyBatchMaximumRangeRule: ProxyBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyBatch) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProxyBatchRequiredCodeRule: ProxyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyBatchRequiredChecksumRule: ProxyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyBatch) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy batch.
    final class ProxyBatchValidator {
        var rules: [any ProxyBatchRule]

        init(rules: [any ProxyBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyBatch) -> [String] {
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

        func requireValid(_ item: ProxyBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyBatch]) -> [String: [String]] {
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

    static func defaultProxyBatchValidator() -> ProxyBatchValidator {
        return ProxyBatchValidator(
            rules: [
                ProxyBatchCodeLengthRule(maxLength: 32),
                ProxyBatchCodePrefixRule(prefix: "Q"),
                ProxyBatchMaximumRangeRule(min: 6.8, max: 436.3),
                ProxyBatchRequiredCodeRule(message: "proxy batch needs an entry"),
                ProxyBatchRequiredChecksumRule(message: "proxy batch needs this field"),
            ]
        )
    }
}
