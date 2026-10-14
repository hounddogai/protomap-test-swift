import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched authorization entry must pass. Check returns its problems, or none.
    protocol BatchedAuthorizationEntryRule {
        func check(_ item: BatchedAuthorizationEntry) -> [String]
    }

    final class BatchedAuthorizationEntryCodePrefixRule: BatchedAuthorizationEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedAuthorizationEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedAuthorizationEntryRequiredNameRule: BatchedAuthorizationEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAuthorizationEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAuthorizationEntryRequiredExternalRefRule: BatchedAuthorizationEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAuthorizationEntry) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAuthorizationEntryMarginRangeRule: BatchedAuthorizationEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedAuthorizationEntry) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedAuthorizationEntryCodeLengthRule: BatchedAuthorizationEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedAuthorizationEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched authorization entry.
    final class BatchedAuthorizationEntryValidator {
        var rules: [any BatchedAuthorizationEntryRule]

        init(rules: [any BatchedAuthorizationEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedAuthorizationEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedAuthorizationEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedAuthorizationEntry]) -> [String: [String]] {
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

    static func defaultBatchedAuthorizationEntryValidator() -> BatchedAuthorizationEntryValidator {
        return BatchedAuthorizationEntryValidator(
            rules: [
                BatchedAuthorizationEntryCodePrefixRule(prefix: "REF"),
                BatchedAuthorizationEntryRequiredNameRule(message: "batched authorization entry needs a value"),
                BatchedAuthorizationEntryRequiredExternalRefRule(
                    message: "batched authorization entry needs an entry"
                ),
                BatchedAuthorizationEntryMarginRangeRule(min: 2.7, max: 1782.8),
                BatchedAuthorizationEntryCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
