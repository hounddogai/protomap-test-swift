import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy task record must pass. Check returns its problems, or none.
    protocol LegacyTaskRecordRule {
        func check(_ item: LegacyTaskRecord) -> [String]
    }

    final class LegacyTaskRecordCurrencyLengthRule: LegacyTaskRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyTaskRecord) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyTaskRecordAttemptsRangeRule: LegacyTaskRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyTaskRecord) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyTaskRecordCodePrefixRule: LegacyTaskRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyTaskRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy task record.
    final class LegacyTaskRecordValidator {
        var rules: [any LegacyTaskRecordRule]

        init(rules: [any LegacyTaskRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyTaskRecord) -> [String] {
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

        func requireValid(_ item: LegacyTaskRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyTaskRecord]) -> [String: [String]] {
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

    static func defaultLegacyTaskRecordValidator() -> LegacyTaskRecordValidator {
        return LegacyTaskRecordValidator(
            rules: [
                LegacyTaskRecordCurrencyLengthRule(maxLength: 16),
                LegacyTaskRecordAttemptsRangeRule(min: 32, max: 80),
                LegacyTaskRecordCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
