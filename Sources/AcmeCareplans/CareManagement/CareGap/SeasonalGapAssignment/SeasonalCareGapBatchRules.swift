import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal care gap batch must pass. Check returns its problems, or none.
    protocol SeasonalCareGapBatchRule {
        func check(_ item: SeasonalCareGapBatch) -> [String]
    }

    final class SeasonalCareGapBatchRequiredTimezoneRule: SeasonalCareGapBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCareGapBatch) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalCareGapBatchRetriesRangeRule: SeasonalCareGapBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCareGapBatch) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalCareGapBatchCodeLengthRule: SeasonalCareGapBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCareGapBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal care gap batch.
    final class SeasonalCareGapBatchValidator {
        var rules: [any SeasonalCareGapBatchRule]

        init(rules: [any SeasonalCareGapBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCareGapBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalCareGapBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCareGapBatch]) -> [String: [String]] {
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

    static func defaultSeasonalCareGapBatchValidator() -> SeasonalCareGapBatchValidator {
        return SeasonalCareGapBatchValidator(
            rules: [
                SeasonalCareGapBatchRequiredTimezoneRule(message: "seasonal care gap batch needs an entry"),
                SeasonalCareGapBatchRetriesRangeRule(min: 16, max: 64),
                SeasonalCareGapBatchCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
