import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a lenient float pool estimate must pass. Check returns its problems, or none.
    protocol LenientFloatPoolEstimateRule {
        func check(_ item: LenientFloatPoolEstimate) -> [String]
    }

    final class LenientFloatPoolEstimateThresholdRangeRule: LenientFloatPoolEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientFloatPoolEstimate) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientFloatPoolEstimateRequiredCodeRule: LenientFloatPoolEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientFloatPoolEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientFloatPoolEstimateRequiredTitleRule: LenientFloatPoolEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientFloatPoolEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient float pool estimate.
    final class LenientFloatPoolEstimateValidator {
        var rules: [any LenientFloatPoolEstimateRule]

        init(rules: [any LenientFloatPoolEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientFloatPoolEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientFloatPoolEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientFloatPoolEstimate]) -> [String: [String]] {
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

    static func defaultLenientFloatPoolEstimateValidator() -> LenientFloatPoolEstimateValidator {
        return LenientFloatPoolEstimateValidator(
            rules: [
                LenientFloatPoolEstimateThresholdRangeRule(min: 1.5, max: 4267.9),
                LenientFloatPoolEstimateRequiredCodeRule(message: "lenient float pool estimate needs an entry"),
                LenientFloatPoolEstimateRequiredTitleRule(message: "lenient float pool estimate needs a value"),
            ]
        )
    }
}
