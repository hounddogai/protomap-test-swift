import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback acuity plan request must pass. Check returns its problems, or none.
    protocol FallbackAcuityPlanRequestRule {
        func check(_ item: FallbackAcuityPlanRequest) -> [String]
    }

    final class FallbackAcuityPlanRequestRequiredTitleRule: FallbackAcuityPlanRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAcuityPlanRequest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAcuityPlanRequestMaximumRangeRule: FallbackAcuityPlanRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackAcuityPlanRequest) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackAcuityPlanRequestRequiredNameRule: FallbackAcuityPlanRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAcuityPlanRequest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAcuityPlanRequestRateRangeRule: FallbackAcuityPlanRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackAcuityPlanRequest) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback acuity plan request.
    final class FallbackAcuityPlanRequestValidator {
        var rules: [any FallbackAcuityPlanRequestRule]

        init(rules: [any FallbackAcuityPlanRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackAcuityPlanRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackAcuityPlanRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackAcuityPlanRequest]) -> [String: [String]] {
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

    static func defaultFallbackAcuityPlanRequestValidator() -> FallbackAcuityPlanRequestValidator {
        return FallbackAcuityPlanRequestValidator(
            rules: [
                FallbackAcuityPlanRequestRequiredTitleRule(message: "fallback acuity plan request needs this field"),
                FallbackAcuityPlanRequestMaximumRangeRule(min: 3.8, max: 61.5),
                FallbackAcuityPlanRequestRequiredNameRule(message: "fallback acuity plan request needs this field"),
                FallbackAcuityPlanRequestRateRangeRule(min: 5.5, max: 2139.3),
            ]
        )
    }
}
