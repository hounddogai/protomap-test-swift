import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding claim must pass. Check returns its problems, or none.
    protocol RoundingClaimRule {
        func check(_ item: RoundingClaim) -> [String]
    }

    final class RoundingClaimAcuityRangeRule: RoundingClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingClaim) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingClaimBatchSizeRangeRule: RoundingClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingClaim) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingClaimAllowedNameRule: RoundingClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RoundingClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class RoundingClaimCodePrefixRule: RoundingClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RoundingClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding claim.
    final class RoundingClaimValidator {
        var rules: [any RoundingClaimRule]

        init(rules: [any RoundingClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingClaim]) -> [String: [String]] {
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

    static func defaultRoundingClaimValidator() -> RoundingClaimValidator {
        return RoundingClaimValidator(
            rules: [
                RoundingClaimAcuityRangeRule(min: 80, max: 3600),
                RoundingClaimBatchSizeRangeRule(min: 80, max: 86400),
                RoundingClaimAllowedNameRule(allowed: ["default", "manual", "legacy"]),
                RoundingClaimCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
