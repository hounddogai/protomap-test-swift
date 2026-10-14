import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback shift baseline must pass. Check returns its problems, or none.
    protocol FallbackShiftBaselineRule {
        func check(_ item: FallbackShiftBaseline) -> [String]
    }

    final class FallbackShiftBaselineExpiresAtRangeRule: FallbackShiftBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackShiftBaseline) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackShiftBaselineCodeLengthRule: FallbackShiftBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackShiftBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackShiftBaselineCodePrefixRule: FallbackShiftBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackShiftBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackShiftBaselineAllowedCodeRule: FallbackShiftBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackShiftBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback shift baseline.
    final class FallbackShiftBaselineValidator {
        var rules: [any FallbackShiftBaselineRule]

        init(rules: [any FallbackShiftBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackShiftBaseline) -> [String] {
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

        func requireValid(_ item: FallbackShiftBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackShiftBaseline]) -> [String: [String]] {
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

    static func defaultFallbackShiftBaselineValidator() -> FallbackShiftBaselineValidator {
        return FallbackShiftBaselineValidator(
            rules: [
                FallbackShiftBaselineExpiresAtRangeRule(min: 64, max: 120),
                FallbackShiftBaselineCodeLengthRule(maxLength: 64),
                FallbackShiftBaselineCodePrefixRule(prefix: "Q"),
                FallbackShiftBaselineAllowedCodeRule(allowed: []),
            ]
        )
    }
}
