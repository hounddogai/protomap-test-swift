import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach ledger must pass. Check returns its problems, or none.
    protocol OutreachLedgerRule {
        func check(_ item: OutreachLedger) -> [String]
    }

    final class OutreachLedgerWeightRangeRule: OutreachLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachLedger) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OutreachLedgerCodePrefixRule: OutreachLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OutreachLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OutreachLedgerSequenceRangeRule: OutreachLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachLedger) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach ledger.
    final class OutreachLedgerValidator {
        var rules: [any OutreachLedgerRule]

        init(rules: [any OutreachLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachLedger]) -> [String: [String]] {
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

    static func defaultOutreachLedgerValidator() -> OutreachLedgerValidator {
        return OutreachLedgerValidator(
            rules: [
                OutreachLedgerWeightRangeRule(min: 3.1, max: 1110.0),
                OutreachLedgerCodePrefixRule(prefix: "OPS"),
                OutreachLedgerSequenceRangeRule(min: 80, max: 120),
            ]
        )
    }
}
