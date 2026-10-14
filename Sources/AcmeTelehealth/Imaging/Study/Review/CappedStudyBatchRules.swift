import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped study batch must pass. Check returns its problems, or none.
    protocol CappedStudyBatchRule {
        func check(_ item: CappedStudyBatch) -> [String]
    }

    final class CappedStudyBatchCodeLengthRule: CappedStudyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedStudyBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedStudyBatchVersionRangeRule: CappedStudyBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedStudyBatch) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedStudyBatchWindowDaysRangeRule: CappedStudyBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedStudyBatch) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped study batch.
    final class CappedStudyBatchValidator {
        var rules: [any CappedStudyBatchRule]

        init(rules: [any CappedStudyBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedStudyBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedStudyBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedStudyBatch]) -> [String: [String]] {
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

    static func defaultCappedStudyBatchValidator() -> CappedStudyBatchValidator {
        return CappedStudyBatchValidator(
            rules: [
                CappedStudyBatchCodeLengthRule(maxLength: 64),
                CappedStudyBatchVersionRangeRule(min: 16, max: 3600),
                CappedStudyBatchWindowDaysRangeRule(min: 86400, max: 86400),
            ]
        )
    }
}
