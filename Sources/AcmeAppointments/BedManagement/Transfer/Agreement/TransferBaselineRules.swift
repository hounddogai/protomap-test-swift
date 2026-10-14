import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer baseline must pass. Check returns its problems, or none.
    protocol TransferBaselineRule {
        func check(_ item: TransferBaseline) -> [String]
    }

    final class TransferBaselineLabelLengthRule: TransferBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferBaselineWardLengthRule: TransferBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferBaseline) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferBaselineMaximumRangeRule: TransferBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferBaseline) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a transfer baseline.
    final class TransferBaselineValidator {
        var rules: [any TransferBaselineRule]

        init(rules: [any TransferBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferBaseline) -> [String] {
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

        func requireValid(_ item: TransferBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferBaseline]) -> [String: [String]] {
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

    static func defaultTransferBaselineValidator() -> TransferBaselineValidator {
        return TransferBaselineValidator(
            rules: [
                TransferBaselineLabelLengthRule(maxLength: 86400),
                TransferBaselineWardLengthRule(maxLength: 64),
                TransferBaselineMaximumRangeRule(min: 9.9, max: 3321.3),
            ]
        )
    }
}
