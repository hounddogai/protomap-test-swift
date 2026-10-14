import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution ledger must pass. Check returns its problems, or none.
    protocol SubstitutionLedgerRule {
        func check(_ item: SubstitutionLedger) -> [String]
    }

    final class SubstitutionLedgerLimitRangeRule: SubstitutionLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionLedger) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SubstitutionLedgerRequiredLabelRule: SubstitutionLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionLedgerCodePrefixRule: SubstitutionLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SubstitutionLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SubstitutionLedgerRequiredWardRule: SubstitutionLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionLedger) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionLedgerAllowedCodeRule: SubstitutionLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SubstitutionLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution ledger.
    final class SubstitutionLedgerValidator {
        var rules: [any SubstitutionLedgerRule]

        init(rules: [any SubstitutionLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionLedger]) -> [String: [String]] {
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

    static func defaultSubstitutionLedgerValidator() -> SubstitutionLedgerValidator {
        return SubstitutionLedgerValidator(
            rules: [
                SubstitutionLedgerLimitRangeRule(min: 16, max: 3600),
                SubstitutionLedgerRequiredLabelRule(message: "substitution ledger needs this field"),
                SubstitutionLedgerCodePrefixRule(prefix: "ACM"),
                SubstitutionLedgerRequiredWardRule(message: "substitution ledger needs a value"),
                SubstitutionLedgerAllowedCodeRule(allowed: ["batched"]),
            ]
        )
    }
}
