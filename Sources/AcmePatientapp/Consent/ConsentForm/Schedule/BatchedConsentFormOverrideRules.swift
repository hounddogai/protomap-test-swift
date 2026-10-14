import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched consent form override must pass. Check returns its problems, or none.
    protocol BatchedConsentFormOverrideRule {
        func check(_ item: BatchedConsentFormOverride) -> [String]
    }

    final class BatchedConsentFormOverrideBatchSizeRangeRule: BatchedConsentFormOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedConsentFormOverride) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedConsentFormOverrideRequiredTitleRule: BatchedConsentFormOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedConsentFormOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedConsentFormOverrideCodePrefixRule: BatchedConsentFormOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedConsentFormOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedConsentFormOverrideTitleLengthRule: BatchedConsentFormOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedConsentFormOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched consent form override.
    final class BatchedConsentFormOverrideValidator {
        var rules: [any BatchedConsentFormOverrideRule]

        init(rules: [any BatchedConsentFormOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedConsentFormOverride) -> [String] {
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

        func requireValid(_ item: BatchedConsentFormOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedConsentFormOverride]) -> [String: [String]] {
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

    static func defaultBatchedConsentFormOverrideValidator() -> BatchedConsentFormOverrideValidator {
        return BatchedConsentFormOverrideValidator(
            rules: [
                BatchedConsentFormOverrideBatchSizeRangeRule(min: 120, max: 3600),
                BatchedConsentFormOverrideRequiredTitleRule(message: "batched consent form override needs this field"),
                BatchedConsentFormOverrideCodePrefixRule(prefix: "X"),
                BatchedConsentFormOverrideTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
