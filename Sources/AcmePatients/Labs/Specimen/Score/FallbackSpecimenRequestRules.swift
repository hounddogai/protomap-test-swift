import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback specimen request must pass. Check returns its problems, or none.
    protocol FallbackSpecimenRequestRule {
        func check(_ item: FallbackSpecimenRequest) -> [String]
    }

    final class FallbackSpecimenRequestAcuityRangeRule: FallbackSpecimenRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackSpecimenRequest) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackSpecimenRequestCodePrefixRule: FallbackSpecimenRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackSpecimenRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackSpecimenRequestBudgetRangeRule: FallbackSpecimenRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackSpecimenRequest) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a fallback specimen request.
    final class FallbackSpecimenRequestValidator {
        var rules: [any FallbackSpecimenRequestRule]

        init(rules: [any FallbackSpecimenRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackSpecimenRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackSpecimenRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackSpecimenRequest]) -> [String: [String]] {
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

    static func defaultFallbackSpecimenRequestValidator() -> FallbackSpecimenRequestValidator {
        return FallbackSpecimenRequestValidator(
            rules: [
                FallbackSpecimenRequestAcuityRangeRule(min: 80, max: 86400),
                FallbackSpecimenRequestCodePrefixRule(prefix: "OPS"),
                FallbackSpecimenRequestBudgetRangeRule(min: 3.1, max: 1677.5),
            ]
        )
    }
}
