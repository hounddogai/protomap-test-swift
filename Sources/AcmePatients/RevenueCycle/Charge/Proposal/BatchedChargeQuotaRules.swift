import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched charge quota must pass. Check returns its problems, or none.
    protocol BatchedChargeQuotaRule {
        func check(_ item: BatchedChargeQuota) -> [String]
    }

    final class BatchedChargeQuotaSourceLengthRule: BatchedChargeQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedChargeQuota) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedChargeQuotaCodeLengthRule: BatchedChargeQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedChargeQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedChargeQuotaRequiredTitleRule: BatchedChargeQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedChargeQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched charge quota.
    final class BatchedChargeQuotaValidator {
        var rules: [any BatchedChargeQuotaRule]

        init(rules: [any BatchedChargeQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedChargeQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedChargeQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedChargeQuota]) -> [String: [String]] {
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

    static func defaultBatchedChargeQuotaValidator() -> BatchedChargeQuotaValidator {
        return BatchedChargeQuotaValidator(
            rules: [
                BatchedChargeQuotaSourceLengthRule(maxLength: 80),
                BatchedChargeQuotaCodeLengthRule(maxLength: 80),
                BatchedChargeQuotaRequiredTitleRule(message: "batched charge quota needs this field"),
            ]
        )
    }
}
