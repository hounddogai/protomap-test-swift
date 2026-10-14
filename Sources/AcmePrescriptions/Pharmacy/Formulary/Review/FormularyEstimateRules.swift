import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary estimate must pass. Check returns its problems, or none.
    protocol FormularyEstimateRule {
        func check(_ item: FormularyEstimate) -> [String]
    }

    final class FormularyEstimateStartsAtRangeRule: FormularyEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyEstimate) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FormularyEstimateGraceDaysRangeRule: FormularyEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyEstimate) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularyEstimateRefillsRangeRule: FormularyEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularyEstimate) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary estimate.
    final class FormularyEstimateValidator {
        var rules: [any FormularyEstimateRule]

        init(rules: [any FormularyEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularyEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularyEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularyEstimate]) -> [String: [String]] {
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

    static func defaultFormularyEstimateValidator() -> FormularyEstimateValidator {
        return FormularyEstimateValidator(
            rules: [
                FormularyEstimateStartsAtRangeRule(min: 80, max: 1000),
                FormularyEstimateGraceDaysRangeRule(min: 255, max: 86400),
                FormularyEstimateRefillsRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
