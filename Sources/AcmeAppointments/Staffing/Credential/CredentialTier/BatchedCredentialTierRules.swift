import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a batched credential tier must pass. Check returns its problems, or none.
    protocol BatchedCredentialTierRule {
        func check(_ item: BatchedCredentialTier) -> [String]
    }

    final class BatchedCredentialTierArchivedGuardRule: BatchedCredentialTierRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: BatchedCredentialTier) -> [String] {
            if item.archived && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class BatchedCredentialTierRequiredChannelRule: BatchedCredentialTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedCredentialTier) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedCredentialTierTitleLengthRule: BatchedCredentialTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCredentialTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCredentialTierLabelLengthRule: BatchedCredentialTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCredentialTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCredentialTierChannelLengthRule: BatchedCredentialTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCredentialTier) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCredentialTierRequiredTitleRule: BatchedCredentialTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedCredentialTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched credential tier.
    final class BatchedCredentialTierValidator {
        var rules: [any BatchedCredentialTierRule]

        init(rules: [any BatchedCredentialTierRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCredentialTier) -> [String] {
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

        func requireValid(_ item: BatchedCredentialTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCredentialTier]) -> [String: [String]] {
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

    static func defaultBatchedCredentialTierValidator() -> BatchedCredentialTierValidator {
        return BatchedCredentialTierValidator(
            rules: [
                BatchedCredentialTierArchivedGuardRule(limit: 86400),
                BatchedCredentialTierRequiredChannelRule(message: "batched credential tier needs an entry"),
                BatchedCredentialTierTitleLengthRule(maxLength: 80),
                BatchedCredentialTierLabelLengthRule(maxLength: 120),
                BatchedCredentialTierChannelLengthRule(maxLength: 86400),
                BatchedCredentialTierRequiredTitleRule(message: "batched credential tier needs this field"),
            ]
        )
    }
}
