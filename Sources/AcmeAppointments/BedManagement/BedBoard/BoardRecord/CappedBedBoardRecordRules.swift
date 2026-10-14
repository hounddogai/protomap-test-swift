import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped bed board record must pass. Check returns its problems, or none.
    protocol CappedBedBoardRecordRule {
        func check(_ item: CappedBedBoardRecord) -> [String]
    }

    final class CappedBedBoardRecordRequiredSegmentRule: CappedBedBoardRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedBedBoardRecord) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedBedBoardRecordCodePrefixRule: CappedBedBoardRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedBedBoardRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedBedBoardRecordCurrencyLengthRule: CappedBedBoardRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedBedBoardRecord) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedBedBoardRecordLimitRangeRule: CappedBedBoardRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedBedBoardRecord) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedBedBoardRecordRequiredCurrencyRule: CappedBedBoardRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedBedBoardRecord) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped bed board record.
    final class CappedBedBoardRecordValidator {
        var rules: [any CappedBedBoardRecordRule]

        init(rules: [any CappedBedBoardRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedBedBoardRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedBedBoardRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedBedBoardRecord]) -> [String: [String]] {
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

    static func defaultCappedBedBoardRecordValidator() -> CappedBedBoardRecordValidator {
        return CappedBedBoardRecordValidator(
            rules: [
                CappedBedBoardRecordRequiredSegmentRule(message: "capped bed board record needs a value"),
                CappedBedBoardRecordCodePrefixRule(prefix: "REF"),
                CappedBedBoardRecordCurrencyLengthRule(maxLength: 1000),
                CappedBedBoardRecordLimitRangeRule(min: 32, max: 1000),
                CappedBedBoardRecordRequiredCurrencyRule(message: "capped bed board record needs a value"),
            ]
        )
    }
}
