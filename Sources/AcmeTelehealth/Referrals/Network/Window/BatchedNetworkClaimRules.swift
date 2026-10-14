import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched network claim must pass. Check returns its problems, or none.
    protocol BatchedNetworkClaimRule {
        func check(_ item: BatchedNetworkClaim) -> [String]
    }

    final class BatchedNetworkClaimCodeLengthRule: BatchedNetworkClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedNetworkClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedNetworkClaimBudgetRangeRule: BatchedNetworkClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedNetworkClaim) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedNetworkClaimRequiredEncounterIDRule: BatchedNetworkClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedNetworkClaim) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedNetworkClaimRequiredLabelRule: BatchedNetworkClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedNetworkClaim) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched network claim.
    final class BatchedNetworkClaimValidator {
        var rules: [any BatchedNetworkClaimRule]

        init(rules: [any BatchedNetworkClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedNetworkClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedNetworkClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedNetworkClaim]) -> [String: [String]] {
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

    static func defaultBatchedNetworkClaimValidator() -> BatchedNetworkClaimValidator {
        return BatchedNetworkClaimValidator(
            rules: [
                BatchedNetworkClaimCodeLengthRule(maxLength: 16),
                BatchedNetworkClaimBudgetRangeRule(min: 2.9, max: 2380.8),
                BatchedNetworkClaimRequiredEncounterIDRule(message: "batched network claim needs a value"),
                BatchedNetworkClaimRequiredLabelRule(message: "batched network claim needs a value"),
            ]
        )
    }
}
