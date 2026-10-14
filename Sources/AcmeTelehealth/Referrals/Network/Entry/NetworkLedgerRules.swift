import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network ledger must pass. Check returns its problems, or none.
    protocol NetworkLedgerRule {
        func check(_ item: NetworkLedger) -> [String]
    }

    final class NetworkLedgerCodePrefixRule: NetworkLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: NetworkLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class NetworkLedgerChannelLengthRule: NetworkLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkLedger) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkLedgerRequiredChannelRule: NetworkLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkLedger) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkLedgerMinimumRangeRule: NetworkLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkLedger) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkLedgerRequiredEncounterIDRule: NetworkLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkLedger) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a network ledger.
    final class NetworkLedgerValidator {
        var rules: [any NetworkLedgerRule]

        init(rules: [any NetworkLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkLedger]) -> [String: [String]] {
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

    static func defaultNetworkLedgerValidator() -> NetworkLedgerValidator {
        return NetworkLedgerValidator(
            rules: [
                NetworkLedgerCodePrefixRule(prefix: "ACM"),
                NetworkLedgerChannelLengthRule(maxLength: 80),
                NetworkLedgerRequiredChannelRule(message: "network ledger needs an entry"),
                NetworkLedgerMinimumRangeRule(min: 1.2, max: 3408.1),
                NetworkLedgerRequiredEncounterIDRule(message: "network ledger needs this field"),
            ]
        )
    }
}
