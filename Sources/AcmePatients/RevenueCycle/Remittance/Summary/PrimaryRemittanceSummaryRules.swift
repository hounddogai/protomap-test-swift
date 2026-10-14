import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary remittance summary must pass. Check returns its problems, or none.
    protocol PrimaryRemittanceSummaryRule {
        func check(_ item: PrimaryRemittanceSummary) -> [String]
    }

    final class PrimaryRemittanceSummaryRequiredCodeRule: PrimaryRemittanceSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRemittanceSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRemittanceSummaryDiagnosisCodeLengthRule: PrimaryRemittanceSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRemittanceSummary) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRemittanceSummaryGraceDaysRangeRule: PrimaryRemittanceSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRemittanceSummary) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryRemittanceSummaryRequiredUnitRule: PrimaryRemittanceSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRemittanceSummary) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRemittanceSummaryBatchSizeRangeRule: PrimaryRemittanceSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRemittanceSummary) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary remittance summary.
    final class PrimaryRemittanceSummaryValidator {
        var rules: [any PrimaryRemittanceSummaryRule]

        init(rules: [any PrimaryRemittanceSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryRemittanceSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryRemittanceSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryRemittanceSummary]) -> [String: [String]] {
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

    static func defaultPrimaryRemittanceSummaryValidator() -> PrimaryRemittanceSummaryValidator {
        return PrimaryRemittanceSummaryValidator(
            rules: [
                PrimaryRemittanceSummaryRequiredCodeRule(message: "primary remittance summary needs a value"),
                PrimaryRemittanceSummaryDiagnosisCodeLengthRule(maxLength: 64),
                PrimaryRemittanceSummaryGraceDaysRangeRule(min: 64, max: 120),
                PrimaryRemittanceSummaryRequiredUnitRule(message: "primary remittance summary needs an entry"),
                PrimaryRemittanceSummaryBatchSizeRangeRule(min: 32, max: 64),
            ]
        )
    }
}
