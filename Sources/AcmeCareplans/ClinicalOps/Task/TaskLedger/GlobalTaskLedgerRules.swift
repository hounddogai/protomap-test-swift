import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global task ledger must pass. Check returns its problems, or none.
    protocol GlobalTaskLedgerRule {
        func check(_ item: GlobalTaskLedger) -> [String]
    }

    final class GlobalTaskLedgerRequiredCodeRule: GlobalTaskLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalTaskLedger) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalTaskLedgerRequiredTitleRule: GlobalTaskLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalTaskLedger) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalTaskLedgerVersionRangeRule: GlobalTaskLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalTaskLedger) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalTaskLedgerTitleLengthRule: GlobalTaskLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalTaskLedger) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global task ledger.
    final class GlobalTaskLedgerValidator {
        var rules: [any GlobalTaskLedgerRule]

        init(rules: [any GlobalTaskLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalTaskLedger) -> [String] {
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

        func requireValid(_ item: GlobalTaskLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalTaskLedger]) -> [String: [String]] {
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

    static func defaultGlobalTaskLedgerValidator() -> GlobalTaskLedgerValidator {
        return GlobalTaskLedgerValidator(
            rules: [
                GlobalTaskLedgerRequiredCodeRule(message: "global task ledger needs a value"),
                GlobalTaskLedgerRequiredTitleRule(message: "global task ledger needs an entry"),
                GlobalTaskLedgerVersionRangeRule(min: 86400, max: 86400),
                GlobalTaskLedgerTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
