import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default follow up variance must pass. Check returns its problems, or none.
    protocol DefaultFollowUpVarianceRule {
        func check(_ item: DefaultFollowUpVariance) -> [String]
    }

    final class DefaultFollowUpVarianceApprovedGuardRule: DefaultFollowUpVarianceRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultFollowUpVariance) -> [String] {
            if item.approved && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class DefaultFollowUpVarianceCodePrefixRule: DefaultFollowUpVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultFollowUpVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultFollowUpVarianceDosageMgRangeRule: DefaultFollowUpVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultFollowUpVariance) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default follow up variance.
    final class DefaultFollowUpVarianceValidator {
        var rules: [any DefaultFollowUpVarianceRule]

        init(rules: [any DefaultFollowUpVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultFollowUpVariance) -> [String] {
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

        func requireValid(_ item: DefaultFollowUpVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultFollowUpVariance]) -> [String: [String]] {
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

    static func defaultDefaultFollowUpVarianceValidator() -> DefaultFollowUpVarianceValidator {
        return DefaultFollowUpVarianceValidator(
            rules: [
                DefaultFollowUpVarianceApprovedGuardRule(limit: 1000),
                DefaultFollowUpVarianceCodePrefixRule(prefix: "Q"),
                DefaultFollowUpVarianceDosageMgRangeRule(min: 3.2, max: 623.8),
            ]
        )
    }
}
