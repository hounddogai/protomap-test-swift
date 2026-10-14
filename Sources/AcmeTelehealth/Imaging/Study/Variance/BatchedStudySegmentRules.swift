import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a batched study segment must pass. Check returns its problems, or none.
    protocol BatchedStudySegmentRule {
        func check(_ item: BatchedStudySegment) -> [String]
    }

    final class BatchedStudySegmentRequiredProcedureCodeRule: BatchedStudySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStudySegment) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedStudySegmentRequiredLabelRule: BatchedStudySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStudySegment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedStudySegmentLimitRangeRule: BatchedStudySegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedStudySegment) -> [String] {
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

    final class BatchedStudySegmentLabelLengthRule: BatchedStudySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedStudySegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedStudySegmentProcedureCodeLengthRule: BatchedStudySegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedStudySegment) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedStudySegmentRequiredTitleRule: BatchedStudySegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStudySegment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched study segment.
    final class BatchedStudySegmentValidator {
        var rules: [any BatchedStudySegmentRule]

        init(rules: [any BatchedStudySegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedStudySegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedStudySegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedStudySegment]) -> [String: [String]] {
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

    static func defaultBatchedStudySegmentValidator() -> BatchedStudySegmentValidator {
        return BatchedStudySegmentValidator(
            rules: [
                BatchedStudySegmentRequiredProcedureCodeRule(message: "batched study segment needs this field"),
                BatchedStudySegmentRequiredLabelRule(message: "batched study segment needs a value"),
                BatchedStudySegmentLimitRangeRule(min: 255, max: 255),
                BatchedStudySegmentLabelLengthRule(maxLength: 64),
                BatchedStudySegmentProcedureCodeLengthRule(maxLength: 80),
                BatchedStudySegmentRequiredTitleRule(message: "batched study segment needs a value"),
            ]
        )
    }
}
