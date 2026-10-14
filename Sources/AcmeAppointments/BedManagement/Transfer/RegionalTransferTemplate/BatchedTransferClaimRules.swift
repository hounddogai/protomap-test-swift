import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched transfer claim must pass. Check returns its problems, or none.
    protocol BatchedTransferClaimRule {
        func check(_ item: BatchedTransferClaim) -> [String]
    }

    final class BatchedTransferClaimAllowedRegionRule: BatchedTransferClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedTransferClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is above maximum"]
            }
            return []
        }
    }

    final class BatchedTransferClaimRetriesRangeRule: BatchedTransferClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedTransferClaim) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedTransferClaimRequiredRegionRule: BatchedTransferClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedTransferClaim) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched transfer claim.
    final class BatchedTransferClaimValidator {
        var rules: [any BatchedTransferClaimRule]

        init(rules: [any BatchedTransferClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedTransferClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedTransferClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedTransferClaim]) -> [String: [String]] {
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

    static func defaultBatchedTransferClaimValidator() -> BatchedTransferClaimValidator {
        return BatchedTransferClaimValidator(
            rules: [
                BatchedTransferClaimAllowedRegionRule(allowed: ["capped", "pending"]),
                BatchedTransferClaimRetriesRangeRule(min: 255, max: 86400),
                BatchedTransferClaimRequiredRegionRule(message: "batched transfer claim needs this field"),
            ]
        )
    }
}
