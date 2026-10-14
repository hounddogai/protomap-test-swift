import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched statement agreement must pass. Check returns its problems, or none.
    protocol BatchedStatementAgreementRule {
        func check(_ item: BatchedStatementAgreement) -> [String]
    }

    final class BatchedStatementAgreementRatioRangeRule: BatchedStatementAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedStatementAgreement) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedStatementAgreementCopayRangeRule: BatchedStatementAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedStatementAgreement) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedStatementAgreementRequiredNameRule: BatchedStatementAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStatementAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched statement agreement.
    final class BatchedStatementAgreementValidator {
        var rules: [any BatchedStatementAgreementRule]

        init(rules: [any BatchedStatementAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedStatementAgreement) -> [String] {
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

        func requireValid(_ item: BatchedStatementAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedStatementAgreement]) -> [String: [String]] {
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

    static func defaultBatchedStatementAgreementValidator() -> BatchedStatementAgreementValidator {
        return BatchedStatementAgreementValidator(
            rules: [
                BatchedStatementAgreementRatioRangeRule(min: 1.1, max: 2925.9),
                BatchedStatementAgreementCopayRangeRule(min: 2.1, max: 679.7),
                BatchedStatementAgreementRequiredNameRule(message: "batched statement agreement needs this field"),
            ]
        )
    }
}
