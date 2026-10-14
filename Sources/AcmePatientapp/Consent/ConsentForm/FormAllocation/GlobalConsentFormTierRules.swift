import AcmePlatform
import Foundation

extension Consent {
    /// A rule a global consent form tier must pass. Check returns its problems, or none.
    protocol GlobalConsentFormTierRule {
        func check(_ item: GlobalConsentFormTier) -> [String]
    }

    final class GlobalConsentFormTierNameLengthRule: GlobalConsentFormTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalConsentFormTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalConsentFormTierRateRangeRule: GlobalConsentFormTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalConsentFormTier) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalConsentFormTierRequiredCodeRule: GlobalConsentFormTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalConsentFormTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global consent form tier.
    final class GlobalConsentFormTierValidator {
        var rules: [any GlobalConsentFormTierRule]

        init(rules: [any GlobalConsentFormTierRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalConsentFormTier) -> [String] {
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

        func requireValid(_ item: GlobalConsentFormTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalConsentFormTier]) -> [String: [String]] {
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

    static func defaultGlobalConsentFormTierValidator() -> GlobalConsentFormTierValidator {
        return GlobalConsentFormTierValidator(
            rules: [
                GlobalConsentFormTierNameLengthRule(maxLength: 255),
                GlobalConsentFormTierRateRangeRule(min: 7.7, max: 4095.1),
                GlobalConsentFormTierRequiredCodeRule(message: "global consent form tier needs a value"),
            ]
        )
    }
}
