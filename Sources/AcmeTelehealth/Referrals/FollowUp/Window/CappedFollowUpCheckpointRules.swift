import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped follow up checkpoint must pass. Check returns its problems, or none.
    protocol CappedFollowUpCheckpointRule {
        func check(_ item: CappedFollowUpCheckpoint) -> [String]
    }

    final class CappedFollowUpCheckpointTimezoneLengthRule: CappedFollowUpCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedFollowUpCheckpoint) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedFollowUpCheckpointChannelLengthRule: CappedFollowUpCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedFollowUpCheckpoint) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedFollowUpCheckpointCodePrefixRule: CappedFollowUpCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedFollowUpCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedFollowUpCheckpointRequiredChannelRule: CappedFollowUpCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedFollowUpCheckpoint) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped follow up checkpoint.
    final class CappedFollowUpCheckpointValidator {
        var rules: [any CappedFollowUpCheckpointRule]

        init(rules: [any CappedFollowUpCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedFollowUpCheckpoint) -> [String] {
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

        func requireValid(_ item: CappedFollowUpCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedFollowUpCheckpoint]) -> [String: [String]] {
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

    static func defaultCappedFollowUpCheckpointValidator() -> CappedFollowUpCheckpointValidator {
        return CappedFollowUpCheckpointValidator(
            rules: [
                CappedFollowUpCheckpointTimezoneLengthRule(maxLength: 16),
                CappedFollowUpCheckpointChannelLengthRule(maxLength: 255),
                CappedFollowUpCheckpointCodePrefixRule(prefix: "REF"),
                CappedFollowUpCheckpointRequiredChannelRule(message: "capped follow up checkpoint needs an entry"),
            ]
        )
    }
}
