import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up checkpoint must pass. Check returns its problems, or none.
    protocol FollowUpCheckpointRule {
        func check(_ item: FollowUpCheckpoint) -> [String]
    }

    final class FollowUpCheckpointAllowedTitleRule: FollowUpCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FollowUpCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    final class FollowUpCheckpointCodePrefixRule: FollowUpCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpCheckpointRequiredPayerRule: FollowUpCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpCheckpoint) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpCheckpointRequiredCodeRule: FollowUpCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpCheckpointActiveGuardRule: FollowUpCheckpointRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: FollowUpCheckpoint) -> [String] {
            if item.active && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class FollowUpCheckpointOwnerIDLengthRule: FollowUpCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpCheckpoint) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up checkpoint.
    final class FollowUpCheckpointValidator {
        var rules: [any FollowUpCheckpointRule]

        init(rules: [any FollowUpCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpCheckpoint) -> [String] {
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

        func requireValid(_ item: FollowUpCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpCheckpoint]) -> [String: [String]] {
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

    static func defaultFollowUpCheckpointValidator() -> FollowUpCheckpointValidator {
        return FollowUpCheckpointValidator(
            rules: [
                FollowUpCheckpointAllowedTitleRule(allowed: []),
                FollowUpCheckpointCodePrefixRule(prefix: "ACM"),
                FollowUpCheckpointRequiredPayerRule(message: "follow up checkpoint needs an entry"),
                FollowUpCheckpointRequiredCodeRule(message: "follow up checkpoint needs this field"),
                FollowUpCheckpointActiveGuardRule(limit: 1000),
                FollowUpCheckpointOwnerIDLengthRule(maxLength: 16),
            ]
        )
    }
}
