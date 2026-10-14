import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist batch must pass. Check returns its problems, or none.
    protocol WorklistBatchRule {
        func check(_ item: WorklistBatch) -> [String]
    }

    final class WorklistBatchAllowedUnitRule: WorklistBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WorklistBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is inconsistent"]
            }
            return []
        }
    }

    final class WorklistBatchCodePrefixRule: WorklistBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WorklistBatchThresholdRangeRule: WorklistBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistBatch) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WorklistBatchCountryLengthRule: WorklistBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistBatch) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistBatchCodeLengthRule: WorklistBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist batch.
    final class WorklistBatchValidator {
        var rules: [any WorklistBatchRule]

        init(rules: [any WorklistBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistBatch]) -> [String: [String]] {
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

    static func defaultWorklistBatchValidator() -> WorklistBatchValidator {
        return WorklistBatchValidator(
            rules: [
                WorklistBatchAllowedUnitRule(allowed: ["tiered", "batched", "tiered"]),
                WorklistBatchCodePrefixRule(prefix: "OPS"),
                WorklistBatchThresholdRangeRule(min: 4.6, max: 4537.2),
                WorklistBatchCountryLengthRule(maxLength: 86400),
                WorklistBatchCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
