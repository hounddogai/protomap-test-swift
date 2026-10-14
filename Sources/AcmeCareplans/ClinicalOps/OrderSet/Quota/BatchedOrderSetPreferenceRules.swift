import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched order set preference must pass. Check returns its problems, or none.
    protocol BatchedOrderSetPreferenceRule {
        func check(_ item: BatchedOrderSetPreference) -> [String]
    }

    final class BatchedOrderSetPreferenceRequiredLabelRule: BatchedOrderSetPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOrderSetPreference) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedOrderSetPreferenceAllowedChannelRule: BatchedOrderSetPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedOrderSetPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is stale"]
            }
            return []
        }
    }

    final class BatchedOrderSetPreferenceCodeLengthRule: BatchedOrderSetPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedOrderSetPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedOrderSetPreferenceRequiredChannelRule: BatchedOrderSetPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOrderSetPreference) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedOrderSetPreferenceTagsLimitRule: BatchedOrderSetPreferenceRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: BatchedOrderSetPreference) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class BatchedOrderSetPreferenceCodePrefixRule: BatchedOrderSetPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedOrderSetPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched order set preference.
    final class BatchedOrderSetPreferenceValidator {
        var rules: [any BatchedOrderSetPreferenceRule]

        init(rules: [any BatchedOrderSetPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedOrderSetPreference) -> [String] {
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

        func requireValid(_ item: BatchedOrderSetPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedOrderSetPreference]) -> [String: [String]] {
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

    static func defaultBatchedOrderSetPreferenceValidator() -> BatchedOrderSetPreferenceValidator {
        return BatchedOrderSetPreferenceValidator(
            rules: [
                BatchedOrderSetPreferenceRequiredLabelRule(message: "batched order set preference needs an entry"),
                BatchedOrderSetPreferenceAllowedChannelRule(allowed: ["legacy", "legacy"]),
                BatchedOrderSetPreferenceCodeLengthRule(maxLength: 32),
                BatchedOrderSetPreferenceRequiredChannelRule(message: "batched order set preference needs an entry"),
                BatchedOrderSetPreferenceTagsLimitRule(maxCount: 86400, banned: []),
                BatchedOrderSetPreferenceCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
