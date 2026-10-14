import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness ledger must pass. Check returns its problems, or none.
    protocol WitnessLedgerRule {
        func check(_ item: WitnessLedger) -> [String]
    }

    final class WitnessLedgerAllowedChannelRule: WitnessLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is below minimum"]
            }
            return []
        }
    }

    final class WitnessLedgerTitleLengthRule: WitnessLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessLedgerChannelLengthRule: WitnessLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessLedger) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessLedgerRequiredCodeRule: WitnessLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessLedgerCodePrefixRule: WitnessLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WitnessLedgerRequiredTitleRule: WitnessLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessLedger) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness ledger.
    final class WitnessLedgerValidator {
        var rules: [any WitnessLedgerRule]

        init(rules: [any WitnessLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessLedger) -> [String] {
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

        func requireValid(_ item: WitnessLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessLedger]) -> [String: [String]] {
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

    static func defaultWitnessLedgerValidator() -> WitnessLedgerValidator {
        return WitnessLedgerValidator(
            rules: [
                WitnessLedgerAllowedChannelRule(allowed: ["weighted", "weighted"]),
                WitnessLedgerTitleLengthRule(maxLength: 64),
                WitnessLedgerChannelLengthRule(maxLength: 16),
                WitnessLedgerRequiredCodeRule(message: "witness ledger needs an entry"),
                WitnessLedgerCodePrefixRule(prefix: "OPS"),
                WitnessLedgerRequiredTitleRule(message: "witness ledger needs a value"),
            ]
        )
    }
}
