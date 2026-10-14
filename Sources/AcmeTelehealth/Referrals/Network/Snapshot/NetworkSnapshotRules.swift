import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network snapshot must pass. Check returns its problems, or none.
    protocol NetworkSnapshotRule {
        func check(_ item: NetworkSnapshot) -> [String]
    }

    final class NetworkSnapshotRequiredSegmentRule: NetworkSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkSnapshot) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkSnapshotRequiredNameRule: NetworkSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkSnapshot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkSnapshotCodePrefixRule: NetworkSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: NetworkSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class NetworkSnapshotRequiredCodeRule: NetworkSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkSnapshotCodeLengthRule: NetworkSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network snapshot.
    final class NetworkSnapshotValidator {
        var rules: [any NetworkSnapshotRule]

        init(rules: [any NetworkSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkSnapshot]) -> [String: [String]] {
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

    static func defaultNetworkSnapshotValidator() -> NetworkSnapshotValidator {
        return NetworkSnapshotValidator(
            rules: [
                NetworkSnapshotRequiredSegmentRule(message: "network snapshot needs a value"),
                NetworkSnapshotRequiredNameRule(message: "network snapshot needs an entry"),
                NetworkSnapshotCodePrefixRule(prefix: "X"),
                NetworkSnapshotRequiredCodeRule(message: "network snapshot needs a value"),
                NetworkSnapshotCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
