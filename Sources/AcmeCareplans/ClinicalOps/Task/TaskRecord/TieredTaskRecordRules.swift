import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered task record must pass. Check returns its problems, or none.
    protocol TieredTaskRecordRule {
        func check(_ item: TieredTaskRecord) -> [String]
    }

    final class TieredTaskRecordCodePrefixRule: TieredTaskRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredTaskRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredTaskRecordDescriptionLengthRule: TieredTaskRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredTaskRecord) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredTaskRecordDurationMinutesRangeRule: TieredTaskRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredTaskRecord) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredTaskRecordRequiredCodeRule: TieredTaskRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredTaskRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered task record.
    final class TieredTaskRecordValidator {
        var rules: [any TieredTaskRecordRule]

        init(rules: [any TieredTaskRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredTaskRecord) -> [String] {
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

        func requireValid(_ item: TieredTaskRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredTaskRecord]) -> [String: [String]] {
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

    static func defaultTieredTaskRecordValidator() -> TieredTaskRecordValidator {
        return TieredTaskRecordValidator(
            rules: [
                TieredTaskRecordCodePrefixRule(prefix: "REF"),
                TieredTaskRecordDescriptionLengthRule(maxLength: 1000),
                TieredTaskRecordDurationMinutesRangeRule(min: 16, max: 1000),
                TieredTaskRecordRequiredCodeRule(message: "tiered task record needs a value"),
            ]
        )
    }
}
