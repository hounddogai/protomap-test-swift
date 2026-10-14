import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy follow up checkpoint must pass. Check returns its problems, or none.
    protocol LegacyFollowUpCheckpointRule {
        func check(_ item: LegacyFollowUpCheckpoint) -> [String]
    }

    final class LegacyFollowUpCheckpointRequiredCodeRule: LegacyFollowUpCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyFollowUpCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyFollowUpCheckpointRequiredTitleRule: LegacyFollowUpCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyFollowUpCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyFollowUpCheckpointChannelLengthRule: LegacyFollowUpCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyFollowUpCheckpoint) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyFollowUpCheckpointRequiredNameRule: LegacyFollowUpCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyFollowUpCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyFollowUpCheckpointCodePrefixRule: LegacyFollowUpCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyFollowUpCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy follow up checkpoint.
    final class LegacyFollowUpCheckpointValidator {
        var rules: [any LegacyFollowUpCheckpointRule]

        init(rules: [any LegacyFollowUpCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyFollowUpCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyFollowUpCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyFollowUpCheckpoint]) -> [String: [String]] {
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

    static func defaultLegacyFollowUpCheckpointValidator() -> LegacyFollowUpCheckpointValidator {
        return LegacyFollowUpCheckpointValidator(
            rules: [
                LegacyFollowUpCheckpointRequiredCodeRule(message: "legacy follow up checkpoint needs a value"),
                LegacyFollowUpCheckpointRequiredTitleRule(message: "legacy follow up checkpoint needs a value"),
                LegacyFollowUpCheckpointChannelLengthRule(maxLength: 255),
                LegacyFollowUpCheckpointRequiredNameRule(message: "legacy follow up checkpoint needs this field"),
                LegacyFollowUpCheckpointCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
