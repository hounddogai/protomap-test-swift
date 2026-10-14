import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement record must pass. Check returns its problems, or none.
    protocol StatementRecordRule {
        func check(_ item: StatementRecord) -> [String]
    }

    final class StatementRecordRequiredCodeRule: StatementRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementRecordMarginRangeRule: StatementRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementRecord) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementRecordCostRangeRule: StatementRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementRecord) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementRecordCodeLengthRule: StatementRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementRecordAllowedCodeRule: StatementRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StatementRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class StatementRecordRequiredSegmentRule: StatementRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementRecord) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a statement record.
    final class StatementRecordValidator {
        var rules: [any StatementRecordRule]

        init(rules: [any StatementRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementRecord) -> [String] {
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

        func requireValid(_ item: StatementRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementRecord]) -> [String: [String]] {
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

    static func defaultStatementRecordValidator() -> StatementRecordValidator {
        return StatementRecordValidator(
            rules: [
                StatementRecordRequiredCodeRule(message: "statement record needs this field"),
                StatementRecordMarginRangeRule(min: 0.1, max: 3317.9),
                StatementRecordCostRangeRule(min: 5.4, max: 2344.1),
                StatementRecordCodeLengthRule(maxLength: 16),
                StatementRecordAllowedCodeRule(allowed: ["legacy", "capped", "pending"]),
                StatementRecordRequiredSegmentRule(message: "statement record needs a value"),
            ]
        )
    }
}
