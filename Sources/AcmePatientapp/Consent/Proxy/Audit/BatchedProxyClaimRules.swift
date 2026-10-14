import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched proxy claim must pass. Check returns its problems, or none.
    protocol BatchedProxyClaimRule {
        func check(_ item: BatchedProxyClaim) -> [String]
    }

    final class BatchedProxyClaimAmountRangeRule: BatchedProxyClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedProxyClaim) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedProxyClaimRequiredSourceRule: BatchedProxyClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedProxyClaim) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedProxyClaimCapacityRangeRule: BatchedProxyClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedProxyClaim) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedProxyClaimCodeLengthRule: BatchedProxyClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProxyClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedProxyClaimSourceLengthRule: BatchedProxyClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProxyClaim) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedProxyClaimPhoneLengthRule: BatchedProxyClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProxyClaim) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched proxy claim.
    final class BatchedProxyClaimValidator {
        var rules: [any BatchedProxyClaimRule]

        init(rules: [any BatchedProxyClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedProxyClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedProxyClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedProxyClaim]) -> [String: [String]] {
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

    static func defaultBatchedProxyClaimValidator() -> BatchedProxyClaimValidator {
        return BatchedProxyClaimValidator(
            rules: [
                BatchedProxyClaimAmountRangeRule(min: 5.7, max: 2905.5),
                BatchedProxyClaimRequiredSourceRule(message: "batched proxy claim needs an entry"),
                BatchedProxyClaimCapacityRangeRule(min: 32, max: 1000),
                BatchedProxyClaimCodeLengthRule(maxLength: 16),
                BatchedProxyClaimSourceLengthRule(maxLength: 16),
                BatchedProxyClaimPhoneLengthRule(maxLength: 3600),
            ]
        )
    }
}
