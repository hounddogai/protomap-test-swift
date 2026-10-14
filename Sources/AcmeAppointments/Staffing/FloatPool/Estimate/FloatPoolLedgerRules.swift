import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool ledger must pass. Check returns its problems, or none.
    protocol FloatPoolLedgerRule {
        func check(_ item: FloatPoolLedger) -> [String]
    }

    final class FloatPoolLedgerThresholdRangeRule: FloatPoolLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolLedger) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolLedgerPinnedGuardRule: FloatPoolLedgerRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FloatPoolLedger) -> [String] {
            if item.pinned && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class FloatPoolLedgerCodePrefixRule: FloatPoolLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FloatPoolLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FloatPoolLedgerLabelLengthRule: FloatPoolLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolLedger) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool ledger.
    final class FloatPoolLedgerValidator {
        var rules: [any FloatPoolLedgerRule]

        init(rules: [any FloatPoolLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolLedger) -> [String] {
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

        func requireValid(_ item: FloatPoolLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolLedger]) -> [String: [String]] {
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

    static func defaultFloatPoolLedgerValidator() -> FloatPoolLedgerValidator {
        return FloatPoolLedgerValidator(
            rules: [
                FloatPoolLedgerThresholdRangeRule(min: 2.8, max: 2595.6),
                FloatPoolLedgerPinnedGuardRule(limit: 3.5),
                FloatPoolLedgerCodePrefixRule(prefix: "Q"),
                FloatPoolLedgerLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
