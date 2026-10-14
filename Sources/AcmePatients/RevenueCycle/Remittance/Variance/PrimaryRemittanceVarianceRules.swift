import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary remittance variance must pass. Check returns its problems, or none.
    protocol PrimaryRemittanceVarianceRule {
        func check(_ item: PrimaryRemittanceVariance) -> [String]
    }

    final class PrimaryRemittanceVarianceWeightRangeRule: PrimaryRemittanceVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRemittanceVariance) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryRemittanceVarianceLimitRangeRule: PrimaryRemittanceVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRemittanceVariance) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryRemittanceVarianceCeilingRangeRule: PrimaryRemittanceVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryRemittanceVariance) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryRemittanceVarianceRequiredUnitRule: PrimaryRemittanceVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRemittanceVariance) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary remittance variance.
    final class PrimaryRemittanceVarianceValidator {
        var rules: [any PrimaryRemittanceVarianceRule]

        init(rules: [any PrimaryRemittanceVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryRemittanceVariance) -> [String] {
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

        func requireValid(_ item: PrimaryRemittanceVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryRemittanceVariance]) -> [String: [String]] {
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

    static func defaultPrimaryRemittanceVarianceValidator() -> PrimaryRemittanceVarianceValidator {
        return PrimaryRemittanceVarianceValidator(
            rules: [
                PrimaryRemittanceVarianceWeightRangeRule(min: 4.4, max: 4965.8),
                PrimaryRemittanceVarianceLimitRangeRule(min: 16, max: 120),
                PrimaryRemittanceVarianceCeilingRangeRule(min: 5.0, max: 433.6),
                PrimaryRemittanceVarianceRequiredUnitRule(message: "primary remittance variance needs this field"),
            ]
        )
    }
}
