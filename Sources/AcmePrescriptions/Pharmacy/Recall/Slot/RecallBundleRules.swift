import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall bundle must pass. Check returns its problems, or none.
    protocol RecallBundleRule {
        func check(_ item: RecallBundle) -> [String]
    }

    final class RecallBundleThresholdRangeRule: RecallBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallBundle) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallBundleAttemptsRangeRule: RecallBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallBundle) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RecallBundleRequiredLabelRule: RecallBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallBundle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallBundleLabelLengthRule: RecallBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallBundle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallBundleRequiredCodeRule: RecallBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall bundle.
    final class RecallBundleValidator {
        var rules: [any RecallBundleRule]

        init(rules: [any RecallBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallBundle) -> [String] {
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

        func requireValid(_ item: RecallBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallBundle]) -> [String: [String]] {
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

    static func defaultRecallBundleValidator() -> RecallBundleValidator {
        return RecallBundleValidator(
            rules: [
                RecallBundleThresholdRangeRule(min: 5.2, max: 2856.7),
                RecallBundleAttemptsRangeRule(min: 120, max: 1000),
                RecallBundleRequiredLabelRule(message: "recall bundle needs an entry"),
                RecallBundleLabelLengthRule(maxLength: 86400),
                RecallBundleRequiredCodeRule(message: "recall bundle needs this field"),
            ]
        )
    }
}
