import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched slot quota must pass. Check returns its problems, or none.
    protocol BatchedSlotQuotaRule {
        func check(_ item: BatchedSlotQuota) -> [String]
    }

    final class BatchedSlotQuotaCountryLengthRule: BatchedSlotQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSlotQuota) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSlotQuotaSpecialtyLengthRule: BatchedSlotQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSlotQuota) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSlotQuotaCodeLengthRule: BatchedSlotQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSlotQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedSlotQuotaRequiredSpecialtyRule: BatchedSlotQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSlotQuota) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched slot quota.
    final class BatchedSlotQuotaValidator {
        var rules: [any BatchedSlotQuotaRule]

        init(rules: [any BatchedSlotQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSlotQuota) -> [String] {
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

        func requireValid(_ item: BatchedSlotQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSlotQuota]) -> [String: [String]] {
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

    static func defaultBatchedSlotQuotaValidator() -> BatchedSlotQuotaValidator {
        return BatchedSlotQuotaValidator(
            rules: [
                BatchedSlotQuotaCountryLengthRule(maxLength: 120),
                BatchedSlotQuotaSpecialtyLengthRule(maxLength: 80),
                BatchedSlotQuotaCodeLengthRule(maxLength: 64),
                BatchedSlotQuotaRequiredSpecialtyRule(message: "batched slot quota needs an entry"),
            ]
        )
    }
}
