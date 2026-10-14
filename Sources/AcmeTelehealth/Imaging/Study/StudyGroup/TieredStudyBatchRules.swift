import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered study batch must pass. Check returns its problems, or none.
    protocol TieredStudyBatchRule {
        func check(_ item: TieredStudyBatch) -> [String]
    }

    final class TieredStudyBatchUpdatedAtRangeRule: TieredStudyBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredStudyBatch) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredStudyBatchRequiredCodeRule: TieredStudyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredStudyBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredStudyBatchCodeLengthRule: TieredStudyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredStudyBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered study batch.
    final class TieredStudyBatchValidator {
        var rules: [any TieredStudyBatchRule]

        init(rules: [any TieredStudyBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredStudyBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredStudyBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredStudyBatch]) -> [String: [String]] {
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

    static func defaultTieredStudyBatchValidator() -> TieredStudyBatchValidator {
        return TieredStudyBatchValidator(
            rules: [
                TieredStudyBatchUpdatedAtRangeRule(min: 80, max: 1000),
                TieredStudyBatchRequiredCodeRule(message: "tiered study batch needs a value"),
                TieredStudyBatchCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
