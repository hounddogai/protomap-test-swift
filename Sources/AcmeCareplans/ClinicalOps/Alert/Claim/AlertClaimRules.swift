import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert claim must pass. Check returns its problems, or none.
    protocol AlertClaimRule {
        func check(_ item: AlertClaim) -> [String]
    }

    final class AlertClaimCodeLengthRule: AlertClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertClaimAllowedCodeRule: AlertClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AlertClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class AlertClaimMaximumRangeRule: AlertClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertClaim) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a alert claim.
    final class AlertClaimValidator {
        var rules: [any AlertClaimRule]

        init(rules: [any AlertClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertClaim) -> [String] {
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

        func requireValid(_ item: AlertClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertClaim]) -> [String: [String]] {
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

    static func defaultAlertClaimValidator() -> AlertClaimValidator {
        return AlertClaimValidator(
            rules: [
                AlertClaimCodeLengthRule(maxLength: 80),
                AlertClaimAllowedCodeRule(allowed: ["scheduled", "strict"]),
                AlertClaimMaximumRangeRule(min: 3.2, max: 2619.6),
            ]
        )
    }
}
