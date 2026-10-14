import AcmePlatform
import Foundation

extension Labs {
    /// A rule a tiered reference range record must pass. Check returns its problems, or none.
    protocol TieredReferenceRangeRecordRule {
        func check(_ item: TieredReferenceRangeRecord) -> [String]
    }

    final class TieredReferenceRangeRecordTitleLengthRule: TieredReferenceRangeRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferenceRangeRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReferenceRangeRecordSummaryLengthRule: TieredReferenceRangeRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReferenceRangeRecord) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReferenceRangeRecordRequiredCodeRule: TieredReferenceRangeRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReferenceRangeRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReferenceRangeRecordPriorityRangeRule: TieredReferenceRangeRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredReferenceRangeRecord) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered reference range record.
    final class TieredReferenceRangeRecordValidator {
        var rules: [any TieredReferenceRangeRecordRule]

        init(rules: [any TieredReferenceRangeRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReferenceRangeRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredReferenceRangeRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReferenceRangeRecord]) -> [String: [String]] {
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

    static func defaultTieredReferenceRangeRecordValidator() -> TieredReferenceRangeRecordValidator {
        return TieredReferenceRangeRecordValidator(
            rules: [
                TieredReferenceRangeRecordTitleLengthRule(maxLength: 80),
                TieredReferenceRangeRecordSummaryLengthRule(maxLength: 64),
                TieredReferenceRangeRecordRequiredCodeRule(message: "tiered reference range record needs this field"),
                TieredReferenceRangeRecordPriorityRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
