import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback claim digest must pass. Check returns its problems, or none.
    protocol FallbackClaimDigestRule {
        func check(_ item: FallbackClaimDigest) -> [String]
    }

    final class FallbackClaimDigestRequiredLabelRule: FallbackClaimDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackClaimDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackClaimDigestRequiredCodeRule: FallbackClaimDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackClaimDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackClaimDigestRefillsRangeRule: FallbackClaimDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackClaimDigest) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback claim digest.
    final class FallbackClaimDigestValidator {
        var rules: [any FallbackClaimDigestRule]

        init(rules: [any FallbackClaimDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackClaimDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackClaimDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackClaimDigest]) -> [String: [String]] {
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

    static func defaultFallbackClaimDigestValidator() -> FallbackClaimDigestValidator {
        return FallbackClaimDigestValidator(
            rules: [
                FallbackClaimDigestRequiredLabelRule(message: "fallback claim digest needs a value"),
                FallbackClaimDigestRequiredCodeRule(message: "fallback claim digest needs an entry"),
                FallbackClaimDigestRefillsRangeRule(min: 32, max: 255),
            ]
        )
    }
}
