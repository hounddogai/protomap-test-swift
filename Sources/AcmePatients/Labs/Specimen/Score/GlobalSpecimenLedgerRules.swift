import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global specimen ledger must pass. Check returns its problems, or none.
    protocol GlobalSpecimenLedgerRule {
        func check(_ item: GlobalSpecimenLedger) -> [String]
    }

    final class GlobalSpecimenLedgerCapacityRangeRule: GlobalSpecimenLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalSpecimenLedger) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalSpecimenLedgerRequiredLabelRule: GlobalSpecimenLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSpecimenLedger) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSpecimenLedgerRequiredTitleRule: GlobalSpecimenLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSpecimenLedger) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSpecimenLedgerCodePrefixRule: GlobalSpecimenLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalSpecimenLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalSpecimenLedgerTitleLengthRule: GlobalSpecimenLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSpecimenLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global specimen ledger.
    final class GlobalSpecimenLedgerValidator {
        var rules: [any GlobalSpecimenLedgerRule]

        init(rules: [any GlobalSpecimenLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSpecimenLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalSpecimenLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSpecimenLedger]) -> [String: [String]] {
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

    static func defaultGlobalSpecimenLedgerValidator() -> GlobalSpecimenLedgerValidator {
        return GlobalSpecimenLedgerValidator(
            rules: [
                GlobalSpecimenLedgerCapacityRangeRule(min: 32, max: 80),
                GlobalSpecimenLedgerRequiredLabelRule(message: "global specimen ledger needs an entry"),
                GlobalSpecimenLedgerRequiredTitleRule(message: "global specimen ledger needs this field"),
                GlobalSpecimenLedgerCodePrefixRule(prefix: "REF"),
                GlobalSpecimenLedgerTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
