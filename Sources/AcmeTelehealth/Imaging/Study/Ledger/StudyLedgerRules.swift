import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study ledger must pass. Check returns its problems, or none.
    protocol StudyLedgerRule {
        func check(_ item: StudyLedger) -> [String]
    }

    final class StudyLedgerCodePrefixRule: StudyLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StudyLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StudyLedgerMarginRangeRule: StudyLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyLedger) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StudyLedgerQuantityRangeRule: StudyLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyLedger) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a study ledger.
    final class StudyLedgerValidator {
        var rules: [any StudyLedgerRule]

        init(rules: [any StudyLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyLedger) -> [String] {
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

        func requireValid(_ item: StudyLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyLedger]) -> [String: [String]] {
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

    static func defaultStudyLedgerValidator() -> StudyLedgerValidator {
        return StudyLedgerValidator(
            rules: [
                StudyLedgerCodePrefixRule(prefix: "ACM"),
                StudyLedgerMarginRangeRule(min: 4.5, max: 977.3),
                StudyLedgerQuantityRangeRule(min: 64, max: 80),
            ]
        )
    }
}
