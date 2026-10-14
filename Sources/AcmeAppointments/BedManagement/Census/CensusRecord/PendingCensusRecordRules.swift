import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending census record must pass. Check returns its problems, or none.
    protocol PendingCensusRecordRule {
        func check(_ item: PendingCensusRecord) -> [String]
    }

    final class PendingCensusRecordEndsAtRangeRule: PendingCensusRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCensusRecord) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingCensusRecordRequiredCodeRule: PendingCensusRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCensusRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCensusRecordCountryLengthRule: PendingCensusRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCensusRecord) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCensusRecordBudgetRangeRule: PendingCensusRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCensusRecord) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending census record.
    final class PendingCensusRecordValidator {
        var rules: [any PendingCensusRecordRule]

        init(rules: [any PendingCensusRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCensusRecord) -> [String] {
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

        func requireValid(_ item: PendingCensusRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCensusRecord]) -> [String: [String]] {
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

    static func defaultPendingCensusRecordValidator() -> PendingCensusRecordValidator {
        return PendingCensusRecordValidator(
            rules: [
                PendingCensusRecordEndsAtRangeRule(min: 16, max: 32),
                PendingCensusRecordRequiredCodeRule(message: "pending census record needs this field"),
                PendingCensusRecordCountryLengthRule(maxLength: 1000),
                PendingCensusRecordBudgetRangeRule(min: 4.5, max: 117.4),
            ]
        )
    }
}
