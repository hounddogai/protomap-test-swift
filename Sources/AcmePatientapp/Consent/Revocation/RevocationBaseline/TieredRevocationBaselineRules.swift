import AcmePlatform
import Foundation

extension Consent {
    /// A rule a tiered revocation baseline must pass. Check returns its problems, or none.
    protocol TieredRevocationBaselineRule {
        func check(_ item: TieredRevocationBaseline) -> [String]
    }

    final class TieredRevocationBaselineRequiredCodeRule: TieredRevocationBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRevocationBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRevocationBaselineCopayRangeRule: TieredRevocationBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRevocationBaseline) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredRevocationBaselineRequiredLabelRule: TieredRevocationBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRevocationBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered revocation baseline.
    final class TieredRevocationBaselineValidator {
        var rules: [any TieredRevocationBaselineRule]

        init(rules: [any TieredRevocationBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRevocationBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredRevocationBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRevocationBaseline]) -> [String: [String]] {
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

    static func defaultTieredRevocationBaselineValidator() -> TieredRevocationBaselineValidator {
        return TieredRevocationBaselineValidator(
            rules: [
                TieredRevocationBaselineRequiredCodeRule(message: "tiered revocation baseline needs an entry"),
                TieredRevocationBaselineCopayRangeRule(min: 6.8, max: 338.7),
                TieredRevocationBaselineRequiredLabelRule(message: "tiered revocation baseline needs a value"),
            ]
        )
    }
}
