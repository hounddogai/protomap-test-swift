import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a regional closure claim must pass. Check returns its problems, or none.
    protocol RegionalClosureClaimRule {
        func check(_ item: RegionalClosureClaim) -> [String]
    }

    final class RegionalClosureClaimAllowedPayerRule: RegionalClosureClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalClosureClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is not allowed"]
            }
            return []
        }
    }

    final class RegionalClosureClaimCodeLengthRule: RegionalClosureClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalClosureClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalClosureClaimTitleLengthRule: RegionalClosureClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalClosureClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalClosureClaimDosageMgRangeRule: RegionalClosureClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalClosureClaim) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalClosureClaimRequiredCodeRule: RegionalClosureClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalClosureClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional closure claim.
    final class RegionalClosureClaimValidator {
        var rules: [any RegionalClosureClaimRule]

        init(rules: [any RegionalClosureClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalClosureClaim) -> [String] {
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

        func requireValid(_ item: RegionalClosureClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalClosureClaim]) -> [String: [String]] {
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

    static func defaultRegionalClosureClaimValidator() -> RegionalClosureClaimValidator {
        return RegionalClosureClaimValidator(
            rules: [
                RegionalClosureClaimAllowedPayerRule(allowed: []),
                RegionalClosureClaimCodeLengthRule(maxLength: 1000),
                RegionalClosureClaimTitleLengthRule(maxLength: 80),
                RegionalClosureClaimDosageMgRangeRule(min: 9.9, max: 2996.1),
                RegionalClosureClaimRequiredCodeRule(message: "regional closure claim needs an entry"),
            ]
        )
    }
}
