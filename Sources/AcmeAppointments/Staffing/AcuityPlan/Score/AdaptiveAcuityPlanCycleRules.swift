import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive acuity plan cycle must pass. Check returns its problems, or none.
    protocol AdaptiveAcuityPlanCycleRule {
        func check(_ item: AdaptiveAcuityPlanCycle) -> [String]
    }

    final class AdaptiveAcuityPlanCycleVersionRangeRule: AdaptiveAcuityPlanCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAcuityPlanCycle) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveAcuityPlanCycleRetriesRangeRule: AdaptiveAcuityPlanCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAcuityPlanCycle) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveAcuityPlanCycleRequiredCodeRule: AdaptiveAcuityPlanCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveAcuityPlanCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveAcuityPlanCycleAmountRangeRule: AdaptiveAcuityPlanCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveAcuityPlanCycle) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive acuity plan cycle.
    final class AdaptiveAcuityPlanCycleValidator {
        var rules: [any AdaptiveAcuityPlanCycleRule]

        init(rules: [any AdaptiveAcuityPlanCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveAcuityPlanCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveAcuityPlanCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveAcuityPlanCycle]) -> [String: [String]] {
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

    static func defaultAdaptiveAcuityPlanCycleValidator() -> AdaptiveAcuityPlanCycleValidator {
        return AdaptiveAcuityPlanCycleValidator(
            rules: [
                AdaptiveAcuityPlanCycleVersionRangeRule(min: 80, max: 80),
                AdaptiveAcuityPlanCycleRetriesRangeRule(min: 64, max: 86400),
                AdaptiveAcuityPlanCycleRequiredCodeRule(message: "adaptive acuity plan cycle needs a value"),
                AdaptiveAcuityPlanCycleAmountRangeRule(min: 0.5, max: 265.1),
            ]
        )
    }
}
