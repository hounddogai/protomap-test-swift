import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a capped goal segment must pass. Check returns its problems, or none.
    protocol CappedGoalSegmentRule {
        func check(_ item: CappedGoalSegment) -> [String]
    }

    final class CappedGoalSegmentCodeLengthRule: CappedGoalSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedGoalSegment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedGoalSegmentBatchSizeRangeRule: CappedGoalSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedGoalSegment) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedGoalSegmentTitleLengthRule: CappedGoalSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedGoalSegment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedGoalSegmentCodePrefixRule: CappedGoalSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedGoalSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped goal segment.
    final class CappedGoalSegmentValidator {
        var rules: [any CappedGoalSegmentRule]

        init(rules: [any CappedGoalSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedGoalSegment) -> [String] {
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

        func requireValid(_ item: CappedGoalSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedGoalSegment]) -> [String: [String]] {
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

    static func defaultCappedGoalSegmentValidator() -> CappedGoalSegmentValidator {
        return CappedGoalSegmentValidator(
            rules: [
                CappedGoalSegmentCodeLengthRule(maxLength: 80),
                CappedGoalSegmentBatchSizeRangeRule(min: 32, max: 120),
                CappedGoalSegmentTitleLengthRule(maxLength: 80),
                CappedGoalSegmentCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
