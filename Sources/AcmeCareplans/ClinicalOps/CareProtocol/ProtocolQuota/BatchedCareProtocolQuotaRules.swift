import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a batched care protocol quota must pass. Check returns its problems, or none.
    protocol BatchedCareProtocolQuotaRule {
        func check(_ item: BatchedCareProtocolQuota) -> [String]
    }

    final class BatchedCareProtocolQuotaAllowedCategoryRule: BatchedCareProtocolQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedCareProtocolQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is out of range"]
            }
            return []
        }
    }

    final class BatchedCareProtocolQuotaDurationMinutesRangeRule: BatchedCareProtocolQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCareProtocolQuota) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedCareProtocolQuotaCategoryLengthRule: BatchedCareProtocolQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCareProtocolQuota) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched care protocol quota.
    final class BatchedCareProtocolQuotaValidator {
        var rules: [any BatchedCareProtocolQuotaRule]

        init(rules: [any BatchedCareProtocolQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCareProtocolQuota) -> [String] {
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

        func requireValid(_ item: BatchedCareProtocolQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCareProtocolQuota]) -> [String: [String]] {
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

    static func defaultBatchedCareProtocolQuotaValidator() -> BatchedCareProtocolQuotaValidator {
        return BatchedCareProtocolQuotaValidator(
            rules: [
                BatchedCareProtocolQuotaAllowedCategoryRule(allowed: ["regional", "lenient"]),
                BatchedCareProtocolQuotaDurationMinutesRangeRule(min: 64, max: 86400),
                BatchedCareProtocolQuotaCategoryLengthRule(maxLength: 120),
            ]
        )
    }
}
