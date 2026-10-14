import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a adaptive handoff ledger must pass. Check returns its problems, or none.
    protocol AdaptiveHandoffLedgerRule {
        func check(_ item: AdaptiveHandoffLedger) -> [String]
    }

    final class AdaptiveHandoffLedgerRequiredUnitRule: AdaptiveHandoffLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveHandoffLedger) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveHandoffLedgerCodePrefixRule: AdaptiveHandoffLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveHandoffLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveHandoffLedgerTitleLengthRule: AdaptiveHandoffLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveHandoffLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive handoff ledger.
    final class AdaptiveHandoffLedgerValidator {
        var rules: [any AdaptiveHandoffLedgerRule]

        init(rules: [any AdaptiveHandoffLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveHandoffLedger) -> [String] {
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

        func requireValid(_ item: AdaptiveHandoffLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveHandoffLedger]) -> [String: [String]] {
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

    static func defaultAdaptiveHandoffLedgerValidator() -> AdaptiveHandoffLedgerValidator {
        return AdaptiveHandoffLedgerValidator(
            rules: [
                AdaptiveHandoffLedgerRequiredUnitRule(message: "adaptive handoff ledger needs this field"),
                AdaptiveHandoffLedgerCodePrefixRule(prefix: "ACM"),
                AdaptiveHandoffLedgerTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
