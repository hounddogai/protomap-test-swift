import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched claim estimate must pass. Check returns its problems, or none.
    protocol BatchedClaimEstimateRule {
        func check(_ item: BatchedClaimEstimate) -> [String]
    }

    final class BatchedClaimEstimateRequiredCodeRule: BatchedClaimEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedClaimEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedClaimEstimateRequiredPayerRule: BatchedClaimEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedClaimEstimate) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedClaimEstimateRequiredExternalRefRule: BatchedClaimEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedClaimEstimate) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedClaimEstimateAllowedCodeRule: BatchedClaimEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedClaimEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a batched claim estimate.
    final class BatchedClaimEstimateValidator {
        var rules: [any BatchedClaimEstimateRule]

        init(rules: [any BatchedClaimEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedClaimEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedClaimEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedClaimEstimate]) -> [String: [String]] {
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

    static func defaultBatchedClaimEstimateValidator() -> BatchedClaimEstimateValidator {
        return BatchedClaimEstimateValidator(
            rules: [
                BatchedClaimEstimateRequiredCodeRule(message: "batched claim estimate needs an entry"),
                BatchedClaimEstimateRequiredPayerRule(message: "batched claim estimate needs a value"),
                BatchedClaimEstimateRequiredExternalRefRule(message: "batched claim estimate needs an entry"),
                BatchedClaimEstimateAllowedCodeRule(allowed: ["regional"]),
            ]
        )
    }
}
