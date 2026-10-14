import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment batch must pass. Check returns its problems, or none.
    protocol AssessmentBatchRule {
        func check(_ item: AssessmentBatch) -> [String]
    }

    final class AssessmentBatchScoreRangeRule: AssessmentBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentBatch) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentBatchRequiredNameRule: AssessmentBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentBatchCodePrefixRule: AssessmentBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AssessmentBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AssessmentBatchRequiredCodeRule: AssessmentBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentBatchRequiredLabelRule: AssessmentBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentBatchNameLengthRule: AssessmentBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment batch.
    final class AssessmentBatchValidator {
        var rules: [any AssessmentBatchRule]

        init(rules: [any AssessmentBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentBatch]) -> [String: [String]] {
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

    static func defaultAssessmentBatchValidator() -> AssessmentBatchValidator {
        return AssessmentBatchValidator(
            rules: [
                AssessmentBatchScoreRangeRule(min: 5.9, max: 1100.7),
                AssessmentBatchRequiredNameRule(message: "assessment batch needs an entry"),
                AssessmentBatchCodePrefixRule(prefix: "OPS"),
                AssessmentBatchRequiredCodeRule(message: "assessment batch needs this field"),
                AssessmentBatchRequiredLabelRule(message: "assessment batch needs an entry"),
                AssessmentBatchNameLengthRule(maxLength: 32),
            ]
        )
    }
}
