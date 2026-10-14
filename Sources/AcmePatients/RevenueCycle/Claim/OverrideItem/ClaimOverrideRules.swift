import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim override must pass. Check returns its problems, or none.
    protocol ClaimOverrideRule {
        func check(_ item: ClaimOverride) -> [String]
    }

    final class ClaimOverrideCodeLengthRule: ClaimOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimOverrideExpiresAtRangeRule: ClaimOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimOverride) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimOverrideLabelLengthRule: ClaimOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimOverride) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim override.
    final class ClaimOverrideValidator {
        var rules: [any ClaimOverrideRule]

        init(rules: [any ClaimOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimOverride) -> [String] {
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

        func requireValid(_ item: ClaimOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimOverride]) -> [String: [String]] {
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

    static func defaultClaimOverrideValidator() -> ClaimOverrideValidator {
        return ClaimOverrideValidator(
            rules: [
                ClaimOverrideCodeLengthRule(maxLength: 1000),
                ClaimOverrideExpiresAtRangeRule(min: 16, max: 32),
                ClaimOverrideLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
