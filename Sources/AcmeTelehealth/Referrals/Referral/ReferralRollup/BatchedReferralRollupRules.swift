import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched referral rollup must pass. Check returns its problems, or none.
    protocol BatchedReferralRollupRule {
        func check(_ item: BatchedReferralRollup) -> [String]
    }

    final class BatchedReferralRollupRequiredProcedureCodeRule: BatchedReferralRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedReferralRollup) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedReferralRollupReviewerLengthRule: BatchedReferralRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedReferralRollup) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedReferralRollupRetriesRangeRule: BatchedReferralRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedReferralRollup) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched referral rollup.
    final class BatchedReferralRollupValidator {
        var rules: [any BatchedReferralRollupRule]

        init(rules: [any BatchedReferralRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedReferralRollup) -> [String] {
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

        func requireValid(_ item: BatchedReferralRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedReferralRollup]) -> [String: [String]] {
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

    static func defaultBatchedReferralRollupValidator() -> BatchedReferralRollupValidator {
        return BatchedReferralRollupValidator(
            rules: [
                BatchedReferralRollupRequiredProcedureCodeRule(message: "batched referral rollup needs this field"),
                BatchedReferralRollupReviewerLengthRule(maxLength: 64),
                BatchedReferralRollupRetriesRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
