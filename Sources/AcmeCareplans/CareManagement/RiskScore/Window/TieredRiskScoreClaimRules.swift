import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered risk score claim must pass. Check returns its problems, or none.
    protocol TieredRiskScoreClaimRule {
        func check(_ item: TieredRiskScoreClaim) -> [String]
    }

    final class TieredRiskScoreClaimExternalRefLengthRule: TieredRiskScoreClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRiskScoreClaim) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRiskScoreClaimCeilingRangeRule: TieredRiskScoreClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRiskScoreClaim) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredRiskScoreClaimCodePrefixRule: TieredRiskScoreClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredRiskScoreClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered risk score claim.
    final class TieredRiskScoreClaimValidator {
        var rules: [any TieredRiskScoreClaimRule]

        init(rules: [any TieredRiskScoreClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRiskScoreClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredRiskScoreClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRiskScoreClaim]) -> [String: [String]] {
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

    static func defaultTieredRiskScoreClaimValidator() -> TieredRiskScoreClaimValidator {
        return TieredRiskScoreClaimValidator(
            rules: [
                TieredRiskScoreClaimExternalRefLengthRule(maxLength: 1000),
                TieredRiskScoreClaimCeilingRangeRule(min: 9.2, max: 3234.5),
                TieredRiskScoreClaimCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
