import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched handoff digest must pass. Check returns its problems, or none.
    protocol BatchedHandoffDigestRule {
        func check(_ item: BatchedHandoffDigest) -> [String]
    }

    final class BatchedHandoffDigestEndsAtRangeRule: BatchedHandoffDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedHandoffDigest) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedHandoffDigestTitleLengthRule: BatchedHandoffDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedHandoffDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedHandoffDigestRequiredCurrencyRule: BatchedHandoffDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedHandoffDigest) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedHandoffDigestDiscountRangeRule: BatchedHandoffDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedHandoffDigest) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedHandoffDigestAllowedCountryRule: BatchedHandoffDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedHandoffDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a batched handoff digest.
    final class BatchedHandoffDigestValidator {
        var rules: [any BatchedHandoffDigestRule]

        init(rules: [any BatchedHandoffDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedHandoffDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedHandoffDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedHandoffDigest]) -> [String: [String]] {
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

    static func defaultBatchedHandoffDigestValidator() -> BatchedHandoffDigestValidator {
        return BatchedHandoffDigestValidator(
            rules: [
                BatchedHandoffDigestEndsAtRangeRule(min: 255, max: 255),
                BatchedHandoffDigestTitleLengthRule(maxLength: 255),
                BatchedHandoffDigestRequiredCurrencyRule(message: "batched handoff digest needs this field"),
                BatchedHandoffDigestDiscountRangeRule(min: 1.7, max: 73.5),
                BatchedHandoffDigestAllowedCountryRule(allowed: ["capped", "legacy", "regional"]),
            ]
        )
    }
}
