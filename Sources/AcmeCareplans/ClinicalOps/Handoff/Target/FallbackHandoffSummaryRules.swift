import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback handoff summary must pass. Check returns its problems, or none.
    protocol FallbackHandoffSummaryRule {
        func check(_ item: FallbackHandoffSummary) -> [String]
    }

    final class FallbackHandoffSummaryPriorityRangeRule: FallbackHandoffSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackHandoffSummary) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackHandoffSummaryLabelLengthRule: FallbackHandoffSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackHandoffSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackHandoffSummarySequenceRangeRule: FallbackHandoffSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackHandoffSummary) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a fallback handoff summary.
    final class FallbackHandoffSummaryValidator {
        var rules: [any FallbackHandoffSummaryRule]

        init(rules: [any FallbackHandoffSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackHandoffSummary) -> [String] {
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

        func requireValid(_ item: FallbackHandoffSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackHandoffSummary]) -> [String: [String]] {
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

    static func defaultFallbackHandoffSummaryValidator() -> FallbackHandoffSummaryValidator {
        return FallbackHandoffSummaryValidator(
            rules: [
                FallbackHandoffSummaryPriorityRangeRule(min: 64, max: 1000),
                FallbackHandoffSummaryLabelLengthRule(maxLength: 64),
                FallbackHandoffSummarySequenceRangeRule(min: 1000, max: 86400),
            ]
        )
    }
}
