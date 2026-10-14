import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient revocation variance must pass. Check returns its problems, or none.
    protocol LenientRevocationVarianceRule {
        func check(_ item: LenientRevocationVariance) -> [String]
    }

    final class LenientRevocationVarianceScoreRangeRule: LenientRevocationVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRevocationVariance) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientRevocationVarianceAllowedCodeRule: LenientRevocationVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientRevocationVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class LenientRevocationVarianceRequiredSummaryRule: LenientRevocationVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRevocationVariance) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient revocation variance.
    final class LenientRevocationVarianceValidator {
        var rules: [any LenientRevocationVarianceRule]

        init(rules: [any LenientRevocationVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRevocationVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientRevocationVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRevocationVariance]) -> [String: [String]] {
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

    static func defaultLenientRevocationVarianceValidator() -> LenientRevocationVarianceValidator {
        return LenientRevocationVarianceValidator(
            rules: [
                LenientRevocationVarianceScoreRangeRule(min: 4.0, max: 1586.8),
                LenientRevocationVarianceAllowedCodeRule(allowed: []),
                LenientRevocationVarianceRequiredSummaryRule(message: "lenient revocation variance needs an entry"),
            ]
        )
    }
}
