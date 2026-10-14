import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional remittance variance must pass. Check returns its problems, or none.
    protocol RegionalRemittanceVarianceRule {
        func check(_ item: RegionalRemittanceVariance) -> [String]
    }

    final class RegionalRemittanceVarianceRequiredSourceRule: RegionalRemittanceVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRemittanceVariance) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalRemittanceVarianceFloorValueRangeRule: RegionalRemittanceVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRemittanceVariance) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalRemittanceVarianceUpdatedAtRangeRule: RegionalRemittanceVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRemittanceVariance) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalRemittanceVarianceQuantityRangeRule: RegionalRemittanceVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalRemittanceVariance) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalRemittanceVarianceAllowedSpecialtyRule: RegionalRemittanceVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalRemittanceVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a regional remittance variance.
    final class RegionalRemittanceVarianceValidator {
        var rules: [any RegionalRemittanceVarianceRule]

        init(rules: [any RegionalRemittanceVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRemittanceVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalRemittanceVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRemittanceVariance]) -> [String: [String]] {
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

    static func defaultRegionalRemittanceVarianceValidator() -> RegionalRemittanceVarianceValidator {
        return RegionalRemittanceVarianceValidator(
            rules: [
                RegionalRemittanceVarianceRequiredSourceRule(message: "regional remittance variance needs a value"),
                RegionalRemittanceVarianceFloorValueRangeRule(min: 5.7, max: 1315.3),
                RegionalRemittanceVarianceUpdatedAtRangeRule(min: 120, max: 3600),
                RegionalRemittanceVarianceQuantityRangeRule(min: 80, max: 120),
                RegionalRemittanceVarianceAllowedSpecialtyRule(allowed: ["manual", "global", "primary"]),
            ]
        )
    }
}
