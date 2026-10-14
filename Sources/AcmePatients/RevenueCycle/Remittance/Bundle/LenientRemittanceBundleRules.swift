import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient remittance bundle must pass. Check returns its problems, or none.
    protocol LenientRemittanceBundleRule {
        func check(_ item: LenientRemittanceBundle) -> [String]
    }

    final class LenientRemittanceBundleAmountRangeRule: LenientRemittanceBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRemittanceBundle) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientRemittanceBundleRateRangeRule: LenientRemittanceBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRemittanceBundle) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientRemittanceBundleRequiredTitleRule: LenientRemittanceBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientRemittanceBundle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientRemittanceBundleCodePrefixRule: LenientRemittanceBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientRemittanceBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient remittance bundle.
    final class LenientRemittanceBundleValidator {
        var rules: [any LenientRemittanceBundleRule]

        init(rules: [any LenientRemittanceBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRemittanceBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientRemittanceBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRemittanceBundle]) -> [String: [String]] {
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

    static func defaultLenientRemittanceBundleValidator() -> LenientRemittanceBundleValidator {
        return LenientRemittanceBundleValidator(
            rules: [
                LenientRemittanceBundleAmountRangeRule(min: 2.4, max: 3354.2),
                LenientRemittanceBundleRateRangeRule(min: 10.0, max: 1306.9),
                LenientRemittanceBundleRequiredTitleRule(message: "lenient remittance bundle needs this field"),
                LenientRemittanceBundleCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
