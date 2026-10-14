import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered claim baseline must pass. Check returns its problems, or none.
    protocol TieredClaimBaselineRule {
        func check(_ item: TieredClaimBaseline) -> [String]
    }

    final class TieredClaimBaselineWeightRangeRule: TieredClaimBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredClaimBaseline) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredClaimBaselineCodePrefixRule: TieredClaimBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredClaimBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredClaimBaselineRequiredCountryRule: TieredClaimBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimBaseline) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredClaimBaselineRequiredOwnerIDRule: TieredClaimBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimBaseline) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredClaimBaselineRequiredLabelRule: TieredClaimBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered claim baseline.
    final class TieredClaimBaselineValidator {
        var rules: [any TieredClaimBaselineRule]

        init(rules: [any TieredClaimBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredClaimBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredClaimBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredClaimBaseline]) -> [String: [String]] {
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

    static func defaultTieredClaimBaselineValidator() -> TieredClaimBaselineValidator {
        return TieredClaimBaselineValidator(
            rules: [
                TieredClaimBaselineWeightRangeRule(min: 5.7, max: 3456.5),
                TieredClaimBaselineCodePrefixRule(prefix: "Q"),
                TieredClaimBaselineRequiredCountryRule(message: "tiered claim baseline needs a value"),
                TieredClaimBaselineRequiredOwnerIDRule(message: "tiered claim baseline needs a value"),
                TieredClaimBaselineRequiredLabelRule(message: "tiered claim baseline needs an entry"),
            ]
        )
    }
}
