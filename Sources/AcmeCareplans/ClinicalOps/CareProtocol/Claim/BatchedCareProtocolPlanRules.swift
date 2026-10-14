import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched care protocol plan must pass. Check returns its problems, or none.
    protocol BatchedCareProtocolPlanRule {
        func check(_ item: BatchedCareProtocolPlan) -> [String]
    }

    final class BatchedCareProtocolPlanCodeLengthRule: BatchedCareProtocolPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCareProtocolPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCareProtocolPlanRateRangeRule: BatchedCareProtocolPlanRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCareProtocolPlan) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedCareProtocolPlanAllowedChannelRule: BatchedCareProtocolPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedCareProtocolPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is missing"]
            }
            return []
        }
    }

    final class BatchedCareProtocolPlanRequiredTitleRule: BatchedCareProtocolPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedCareProtocolPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched care protocol plan.
    final class BatchedCareProtocolPlanValidator {
        var rules: [any BatchedCareProtocolPlanRule]

        init(rules: [any BatchedCareProtocolPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCareProtocolPlan) -> [String] {
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

        func requireValid(_ item: BatchedCareProtocolPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCareProtocolPlan]) -> [String: [String]] {
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

    static func defaultBatchedCareProtocolPlanValidator() -> BatchedCareProtocolPlanValidator {
        return BatchedCareProtocolPlanValidator(
            rules: [
                BatchedCareProtocolPlanCodeLengthRule(maxLength: 1000),
                BatchedCareProtocolPlanRateRangeRule(min: 5.5, max: 4347.6),
                BatchedCareProtocolPlanAllowedChannelRule(allowed: ["weighted", "pending", "regional"]),
                BatchedCareProtocolPlanRequiredTitleRule(message: "batched care protocol plan needs this field"),
            ]
        )
    }
}
