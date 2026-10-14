import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool claim must pass. Check returns its problems, or none.
    protocol FloatPoolClaimRule {
        func check(_ item: FloatPoolClaim) -> [String]
    }

    final class FloatPoolClaimMinimumRangeRule: FloatPoolClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolClaim) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FloatPoolClaimAllowedCodeRule: FloatPoolClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class FloatPoolClaimLabelLengthRule: FloatPoolClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolClaim) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolClaimCodePrefixRule: FloatPoolClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FloatPoolClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool claim.
    final class FloatPoolClaimValidator {
        var rules: [any FloatPoolClaimRule]

        init(rules: [any FloatPoolClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolClaim) -> [String] {
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

        func requireValid(_ item: FloatPoolClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolClaim]) -> [String: [String]] {
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

    static func defaultFloatPoolClaimValidator() -> FloatPoolClaimValidator {
        return FloatPoolClaimValidator(
            rules: [
                FloatPoolClaimMinimumRangeRule(min: 3.3, max: 990.2),
                FloatPoolClaimAllowedCodeRule(allowed: ["adaptive", "lenient", "scheduled"]),
                FloatPoolClaimLabelLengthRule(maxLength: 1000),
                FloatPoolClaimCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
