import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending network snapshot must pass. Check returns its problems, or none.
    protocol PendingNetworkSnapshotRule {
        func check(_ item: PendingNetworkSnapshot) -> [String]
    }

    final class PendingNetworkSnapshotChannelLengthRule: PendingNetworkSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingNetworkSnapshot) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingNetworkSnapshotCodeLengthRule: PendingNetworkSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingNetworkSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingNetworkSnapshotRequiredChannelRule: PendingNetworkSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingNetworkSnapshot) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingNetworkSnapshotRequiredTitleRule: PendingNetworkSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingNetworkSnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingNetworkSnapshotAllowedCodeRule: PendingNetworkSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingNetworkSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a pending network snapshot.
    final class PendingNetworkSnapshotValidator {
        var rules: [any PendingNetworkSnapshotRule]

        init(rules: [any PendingNetworkSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingNetworkSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingNetworkSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingNetworkSnapshot]) -> [String: [String]] {
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

    static func defaultPendingNetworkSnapshotValidator() -> PendingNetworkSnapshotValidator {
        return PendingNetworkSnapshotValidator(
            rules: [
                PendingNetworkSnapshotChannelLengthRule(maxLength: 80),
                PendingNetworkSnapshotCodeLengthRule(maxLength: 16),
                PendingNetworkSnapshotRequiredChannelRule(message: "pending network snapshot needs this field"),
                PendingNetworkSnapshotRequiredTitleRule(message: "pending network snapshot needs a value"),
                PendingNetworkSnapshotAllowedCodeRule(allowed: []),
            ]
        )
    }
}
