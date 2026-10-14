import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility baseline must pass. Check returns its problems, or none.
    protocol EligibilityBaselineRule {
        func check(_ item: EligibilityBaseline) -> [String]
    }

    final class EligibilityBaselineAllowedCodeRule: EligibilityBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class EligibilityBaselineBatchSizeRangeRule: EligibilityBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityBaseline) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class EligibilityBaselineCodePrefixRule: EligibilityBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class EligibilityBaselineGraceDaysRangeRule: EligibilityBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityBaseline) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class EligibilityBaselineActiveGuardRule: EligibilityBaselineRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: EligibilityBaseline) -> [String] {
            if item.active && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class EligibilityBaselineCodeLengthRule: EligibilityBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility baseline.
    final class EligibilityBaselineValidator {
        var rules: [any EligibilityBaselineRule]

        init(rules: [any EligibilityBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityBaseline) -> [String] {
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

        func requireValid(_ item: EligibilityBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityBaseline]) -> [String: [String]] {
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

    static func defaultEligibilityBaselineValidator() -> EligibilityBaselineValidator {
        return EligibilityBaselineValidator(
            rules: [
                EligibilityBaselineAllowedCodeRule(allowed: ["rolling", "scheduled", "adaptive"]),
                EligibilityBaselineBatchSizeRangeRule(min: 80, max: 1000),
                EligibilityBaselineCodePrefixRule(prefix: "ACM"),
                EligibilityBaselineGraceDaysRangeRule(min: 32, max: 64),
                EligibilityBaselineActiveGuardRule(limit: 5.4),
                EligibilityBaselineCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
