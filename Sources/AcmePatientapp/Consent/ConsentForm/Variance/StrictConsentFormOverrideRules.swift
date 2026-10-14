import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict consent form override must pass. Check returns its problems, or none.
    protocol StrictConsentFormOverrideRule {
        func check(_ item: StrictConsentFormOverride) -> [String]
    }

    final class StrictConsentFormOverrideMarginRangeRule: StrictConsentFormOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictConsentFormOverride) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictConsentFormOverrideCeilingRangeRule: StrictConsentFormOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictConsentFormOverride) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictConsentFormOverrideAmountRangeRule: StrictConsentFormOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictConsentFormOverride) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictConsentFormOverridePayerLengthRule: StrictConsentFormOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictConsentFormOverride) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict consent form override.
    final class StrictConsentFormOverrideValidator {
        var rules: [any StrictConsentFormOverrideRule]

        init(rules: [any StrictConsentFormOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictConsentFormOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictConsentFormOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictConsentFormOverride]) -> [String: [String]] {
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

    static func defaultStrictConsentFormOverrideValidator() -> StrictConsentFormOverrideValidator {
        return StrictConsentFormOverrideValidator(
            rules: [
                StrictConsentFormOverrideMarginRangeRule(min: 0.8, max: 2029.8),
                StrictConsentFormOverrideCeilingRangeRule(min: 8.3, max: 2297.6),
                StrictConsentFormOverrideAmountRangeRule(min: 9.1, max: 1184.6),
                StrictConsentFormOverridePayerLengthRule(maxLength: 255),
            ]
        )
    }
}
