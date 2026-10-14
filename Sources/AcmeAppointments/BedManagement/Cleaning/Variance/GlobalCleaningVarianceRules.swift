import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global cleaning variance must pass. Check returns its problems, or none.
    protocol GlobalCleaningVarianceRule {
        func check(_ item: GlobalCleaningVariance) -> [String]
    }

    final class GlobalCleaningVarianceCostRangeRule: GlobalCleaningVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCleaningVariance) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalCleaningVarianceCreatedAtRangeRule: GlobalCleaningVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCleaningVariance) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalCleaningVarianceRequiredLabelRule: GlobalCleaningVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCleaningVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global cleaning variance.
    final class GlobalCleaningVarianceValidator {
        var rules: [any GlobalCleaningVarianceRule]

        init(rules: [any GlobalCleaningVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCleaningVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalCleaningVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCleaningVariance]) -> [String: [String]] {
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

    static func defaultGlobalCleaningVarianceValidator() -> GlobalCleaningVarianceValidator {
        return GlobalCleaningVarianceValidator(
            rules: [
                GlobalCleaningVarianceCostRangeRule(min: 3.6, max: 988.1),
                GlobalCleaningVarianceCreatedAtRangeRule(min: 16, max: 86400),
                GlobalCleaningVarianceRequiredLabelRule(message: "global cleaning variance needs an entry"),
            ]
        )
    }
}
