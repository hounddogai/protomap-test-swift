import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive language claim must pass. Check returns its problems, or none.
    protocol AdaptiveLanguageClaimRule {
        func check(_ item: AdaptiveLanguageClaim) -> [String]
    }

    final class AdaptiveLanguageClaimCodePrefixRule: AdaptiveLanguageClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveLanguageClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveLanguageClaimRegionLengthRule: AdaptiveLanguageClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveLanguageClaim) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveLanguageClaimLabelLengthRule: AdaptiveLanguageClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveLanguageClaim) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveLanguageClaimDiscountRangeRule: AdaptiveLanguageClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveLanguageClaim) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveLanguageClaimRequiredCodeRule: AdaptiveLanguageClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveLanguageClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive language claim.
    final class AdaptiveLanguageClaimValidator {
        var rules: [any AdaptiveLanguageClaimRule]

        init(rules: [any AdaptiveLanguageClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveLanguageClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveLanguageClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveLanguageClaim]) -> [String: [String]] {
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

    static func defaultAdaptiveLanguageClaimValidator() -> AdaptiveLanguageClaimValidator {
        return AdaptiveLanguageClaimValidator(
            rules: [
                AdaptiveLanguageClaimCodePrefixRule(prefix: "Q"),
                AdaptiveLanguageClaimRegionLengthRule(maxLength: 86400),
                AdaptiveLanguageClaimLabelLengthRule(maxLength: 1000),
                AdaptiveLanguageClaimDiscountRangeRule(min: 2.0, max: 101.6),
                AdaptiveLanguageClaimRequiredCodeRule(message: "adaptive language claim needs an entry"),
            ]
        )
    }
}
