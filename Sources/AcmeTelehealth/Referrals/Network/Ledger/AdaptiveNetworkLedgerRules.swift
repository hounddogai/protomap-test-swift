import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive network ledger must pass. Check returns its problems, or none.
    protocol AdaptiveNetworkLedgerRule {
        func check(_ item: AdaptiveNetworkLedger) -> [String]
    }

    final class AdaptiveNetworkLedgerRequiredNameRule: AdaptiveNetworkLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveNetworkLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveNetworkLedgerNameLengthRule: AdaptiveNetworkLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveNetworkLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveNetworkLedgerRequiredLabelRule: AdaptiveNetworkLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveNetworkLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveNetworkLedgerVisitMinutesRangeRule: AdaptiveNetworkLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveNetworkLedger) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive network ledger.
    final class AdaptiveNetworkLedgerValidator {
        var rules: [any AdaptiveNetworkLedgerRule]

        init(rules: [any AdaptiveNetworkLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveNetworkLedger) -> [String] {
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

        func requireValid(_ item: AdaptiveNetworkLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveNetworkLedger]) -> [String: [String]] {
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

    static func defaultAdaptiveNetworkLedgerValidator() -> AdaptiveNetworkLedgerValidator {
        return AdaptiveNetworkLedgerValidator(
            rules: [
                AdaptiveNetworkLedgerRequiredNameRule(message: "adaptive network ledger needs this field"),
                AdaptiveNetworkLedgerNameLengthRule(maxLength: 32),
                AdaptiveNetworkLedgerRequiredLabelRule(message: "adaptive network ledger needs an entry"),
                AdaptiveNetworkLedgerVisitMinutesRangeRule(min: 16, max: 86400),
            ]
        )
    }
}
