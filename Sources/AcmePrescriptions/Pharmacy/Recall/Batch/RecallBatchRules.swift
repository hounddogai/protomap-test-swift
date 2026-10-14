import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall batch must pass. Check returns its problems, or none.
    protocol RecallBatchRule {
        func check(_ item: RecallBatch) -> [String]
    }

    final class RecallBatchAllowedCodeRule: RecallBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RecallBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class RecallBatchRequiredLabelRule: RecallBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallBatch) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallBatchVersionRangeRule: RecallBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallBatch) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RecallBatchAttemptsRangeRule: RecallBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallBatch) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a recall batch.
    final class RecallBatchValidator {
        var rules: [any RecallBatchRule]

        init(rules: [any RecallBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallBatch]) -> [String: [String]] {
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

    static func defaultRecallBatchValidator() -> RecallBatchValidator {
        return RecallBatchValidator(
            rules: [
                RecallBatchAllowedCodeRule(allowed: []),
                RecallBatchRequiredLabelRule(message: "recall batch needs a value"),
                RecallBatchVersionRangeRule(min: 32, max: 86400),
                RecallBatchAttemptsRangeRule(min: 64, max: 64),
            ]
        )
    }
}
