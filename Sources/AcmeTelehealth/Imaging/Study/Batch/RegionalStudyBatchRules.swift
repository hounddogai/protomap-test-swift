import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional study batch must pass. Check returns its problems, or none.
    protocol RegionalStudyBatchRule {
        func check(_ item: RegionalStudyBatch) -> [String]
    }

    final class RegionalStudyBatchRequiredPayerRule: RegionalStudyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalStudyBatch) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalStudyBatchLabelLengthRule: RegionalStudyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalStudyBatch) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalStudyBatchRevisionRangeRule: RegionalStudyBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalStudyBatch) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalStudyBatchRequiredLabelRule: RegionalStudyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalStudyBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional study batch.
    final class RegionalStudyBatchValidator {
        var rules: [any RegionalStudyBatchRule]

        init(rules: [any RegionalStudyBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalStudyBatch) -> [String] {
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

        func requireValid(_ item: RegionalStudyBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalStudyBatch]) -> [String: [String]] {
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

    static func defaultRegionalStudyBatchValidator() -> RegionalStudyBatchValidator {
        return RegionalStudyBatchValidator(
            rules: [
                RegionalStudyBatchRequiredPayerRule(message: "regional study batch needs this field"),
                RegionalStudyBatchLabelLengthRule(maxLength: 32),
                RegionalStudyBatchRevisionRangeRule(min: 86400, max: 86400),
                RegionalStudyBatchRequiredLabelRule(message: "regional study batch needs an entry"),
            ]
        )
    }
}
