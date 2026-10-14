import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped transfer threshold must pass. Check returns its problems, or none.
    protocol CappedTransferThresholdRule {
        func check(_ item: CappedTransferThreshold) -> [String]
    }

    final class CappedTransferThresholdScoreRangeRule: CappedTransferThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedTransferThreshold) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedTransferThresholdProcedureCodeLengthRule: CappedTransferThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedTransferThreshold) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedTransferThresholdCopayRangeRule: CappedTransferThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedTransferThreshold) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped transfer threshold.
    final class CappedTransferThresholdValidator {
        var rules: [any CappedTransferThresholdRule]

        init(rules: [any CappedTransferThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedTransferThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedTransferThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedTransferThreshold]) -> [String: [String]] {
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

    static func defaultCappedTransferThresholdValidator() -> CappedTransferThresholdValidator {
        return CappedTransferThresholdValidator(
            rules: [
                CappedTransferThresholdScoreRangeRule(min: 8.9, max: 3675.4),
                CappedTransferThresholdProcedureCodeLengthRule(maxLength: 16),
                CappedTransferThresholdCopayRangeRule(min: 2.2, max: 310.8),
            ]
        )
    }
}
