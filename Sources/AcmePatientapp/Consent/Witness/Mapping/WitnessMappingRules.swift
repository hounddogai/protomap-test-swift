import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness mapping must pass. Check returns its problems, or none.
    protocol WitnessMappingRule {
        func check(_ item: WitnessMapping) -> [String]
    }

    final class WitnessMappingDiscountRangeRule: WitnessMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessMapping) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessMappingScoreRangeRule: WitnessMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessMapping) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessMappingRequiredNameRule: WitnessMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness mapping.
    final class WitnessMappingValidator {
        var rules: [any WitnessMappingRule]

        init(rules: [any WitnessMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessMapping]) -> [String: [String]] {
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

    static func defaultWitnessMappingValidator() -> WitnessMappingValidator {
        return WitnessMappingValidator(
            rules: [
                WitnessMappingDiscountRangeRule(min: 0.2, max: 2866.1),
                WitnessMappingScoreRangeRule(min: 4.0, max: 1142.0),
                WitnessMappingRequiredNameRule(message: "witness mapping needs this field"),
            ]
        )
    }
}
