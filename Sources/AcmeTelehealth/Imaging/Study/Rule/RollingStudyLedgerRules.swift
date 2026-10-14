import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling study ledger must pass. Check returns its problems, or none.
    protocol RollingStudyLedgerRule {
        func check(_ item: RollingStudyLedger) -> [String]
    }

    final class RollingStudyLedgerThresholdRangeRule: RollingStudyLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingStudyLedger) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingStudyLedgerBatchSizeRangeRule: RollingStudyLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingStudyLedger) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingStudyLedgerCopayRangeRule: RollingStudyLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingStudyLedger) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingStudyLedgerAllowedLabelRule: RollingStudyLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingStudyLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    final class RollingStudyLedgerLabelLengthRule: RollingStudyLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingStudyLedger) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling study ledger.
    final class RollingStudyLedgerValidator {
        var rules: [any RollingStudyLedgerRule]

        init(rules: [any RollingStudyLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingStudyLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingStudyLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingStudyLedger]) -> [String: [String]] {
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

    static func defaultRollingStudyLedgerValidator() -> RollingStudyLedgerValidator {
        return RollingStudyLedgerValidator(
            rules: [
                RollingStudyLedgerThresholdRangeRule(min: 6.6, max: 767.9),
                RollingStudyLedgerBatchSizeRangeRule(min: 1000, max: 86400),
                RollingStudyLedgerCopayRangeRule(min: 5.5, max: 1769.3),
                RollingStudyLedgerAllowedLabelRule(allowed: ["default"]),
                RollingStudyLedgerLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
