import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary statement record must pass. Check returns its problems, or none.
    protocol PrimaryStatementRecordRule {
        func check(_ item: PrimaryStatementRecord) -> [String]
    }

    final class PrimaryStatementRecordRefillsRangeRule: PrimaryStatementRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryStatementRecord) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryStatementRecordRequiredCurrencyRule: PrimaryStatementRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryStatementRecord) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryStatementRecordRequiredCodeRule: PrimaryStatementRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryStatementRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryStatementRecordPayerLengthRule: PrimaryStatementRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryStatementRecord) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryStatementRecordDosageMgRangeRule: PrimaryStatementRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryStatementRecord) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary statement record.
    final class PrimaryStatementRecordValidator {
        var rules: [any PrimaryStatementRecordRule]

        init(rules: [any PrimaryStatementRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryStatementRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryStatementRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryStatementRecord]) -> [String: [String]] {
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

    static func defaultPrimaryStatementRecordValidator() -> PrimaryStatementRecordValidator {
        return PrimaryStatementRecordValidator(
            rules: [
                PrimaryStatementRecordRefillsRangeRule(min: 80, max: 1000),
                PrimaryStatementRecordRequiredCurrencyRule(message: "primary statement record needs a value"),
                PrimaryStatementRecordRequiredCodeRule(message: "primary statement record needs a value"),
                PrimaryStatementRecordPayerLengthRule(maxLength: 255),
                PrimaryStatementRecordDosageMgRangeRule(min: 6.4, max: 3844.6),
            ]
        )
    }
}
