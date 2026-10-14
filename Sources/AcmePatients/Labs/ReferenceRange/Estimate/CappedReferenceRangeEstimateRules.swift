import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped reference range estimate must pass. Check returns its problems, or none.
    protocol CappedReferenceRangeEstimateRule {
        func check(_ item: CappedReferenceRangeEstimate) -> [String]
    }

    final class CappedReferenceRangeEstimateAttemptsRangeRule: CappedReferenceRangeEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedReferenceRangeEstimate) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedReferenceRangeEstimateRequiredCodeRule: CappedReferenceRangeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReferenceRangeEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedReferenceRangeEstimateRequiredCategoryRule: CappedReferenceRangeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReferenceRangeEstimate) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedReferenceRangeEstimateCopayRangeRule: CappedReferenceRangeEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedReferenceRangeEstimate) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedReferenceRangeEstimateCreatedAtRangeRule: CappedReferenceRangeEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedReferenceRangeEstimate) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedReferenceRangeEstimateRequiredNameRule: CappedReferenceRangeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReferenceRangeEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped reference range estimate.
    final class CappedReferenceRangeEstimateValidator {
        var rules: [any CappedReferenceRangeEstimateRule]

        init(rules: [any CappedReferenceRangeEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedReferenceRangeEstimate) -> [String] {
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

        func requireValid(_ item: CappedReferenceRangeEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedReferenceRangeEstimate]) -> [String: [String]] {
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

    static func defaultCappedReferenceRangeEstimateValidator() -> CappedReferenceRangeEstimateValidator {
        return CappedReferenceRangeEstimateValidator(
            rules: [
                CappedReferenceRangeEstimateAttemptsRangeRule(min: 32, max: 120),
                CappedReferenceRangeEstimateRequiredCodeRule(
                    message: "capped reference range estimate needs this field"
                ),
                CappedReferenceRangeEstimateRequiredCategoryRule(
                    message: "capped reference range estimate needs an entry"
                ),
                CappedReferenceRangeEstimateCopayRangeRule(min: 1.8, max: 4029.5),
                CappedReferenceRangeEstimateCreatedAtRangeRule(min: 120, max: 255),
                CappedReferenceRangeEstimateRequiredNameRule(
                    message: "capped reference range estimate needs an entry"
                ),
            ]
        )
    }
}
