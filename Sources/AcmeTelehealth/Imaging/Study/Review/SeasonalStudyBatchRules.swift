import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal study batch must pass. Check returns its problems, or none.
    protocol SeasonalStudyBatchRule {
        func check(_ item: SeasonalStudyBatch) -> [String]
    }

    final class SeasonalStudyBatchCodePrefixRule: SeasonalStudyBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalStudyBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalStudyBatchScoreRangeRule: SeasonalStudyBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalStudyBatch) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalStudyBatchNameLengthRule: SeasonalStudyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalStudyBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalStudyBatchRequiredCodeRule: SeasonalStudyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalStudyBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalStudyBatchRequiredNameRule: SeasonalStudyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalStudyBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalStudyBatchPayerLengthRule: SeasonalStudyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalStudyBatch) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal study batch.
    final class SeasonalStudyBatchValidator {
        var rules: [any SeasonalStudyBatchRule]

        init(rules: [any SeasonalStudyBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalStudyBatch) -> [String] {
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

        func requireValid(_ item: SeasonalStudyBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalStudyBatch]) -> [String: [String]] {
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

    static func defaultSeasonalStudyBatchValidator() -> SeasonalStudyBatchValidator {
        return SeasonalStudyBatchValidator(
            rules: [
                SeasonalStudyBatchCodePrefixRule(prefix: "REF"),
                SeasonalStudyBatchScoreRangeRule(min: 7.3, max: 4478.4),
                SeasonalStudyBatchNameLengthRule(maxLength: 32),
                SeasonalStudyBatchRequiredCodeRule(message: "seasonal study batch needs this field"),
                SeasonalStudyBatchRequiredNameRule(message: "seasonal study batch needs a value"),
                SeasonalStudyBatchPayerLengthRule(maxLength: 64),
            ]
        )
    }
}
