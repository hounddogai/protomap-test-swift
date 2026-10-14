import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback reference range variance must pass. Check returns its problems, or none.
    protocol FallbackReferenceRangeVarianceRule {
        func check(_ item: FallbackReferenceRangeVariance) -> [String]
    }

    final class FallbackReferenceRangeVarianceRequiredCodeRule: FallbackReferenceRangeVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackReferenceRangeVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackReferenceRangeVarianceAllowedRegionRule: FallbackReferenceRangeVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackReferenceRangeVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is out of range"]
            }
            return []
        }
    }

    final class FallbackReferenceRangeVarianceRatioRangeRule: FallbackReferenceRangeVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackReferenceRangeVariance) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackReferenceRangeVarianceCapacityRangeRule: FallbackReferenceRangeVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackReferenceRangeVariance) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback reference range variance.
    final class FallbackReferenceRangeVarianceValidator {
        var rules: [any FallbackReferenceRangeVarianceRule]

        init(rules: [any FallbackReferenceRangeVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackReferenceRangeVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackReferenceRangeVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackReferenceRangeVariance]) -> [String: [String]] {
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

    static func defaultFallbackReferenceRangeVarianceValidator() -> FallbackReferenceRangeVarianceValidator {
        return FallbackReferenceRangeVarianceValidator(
            rules: [
                FallbackReferenceRangeVarianceRequiredCodeRule(
                    message: "fallback reference range variance needs a value"
                ),
                FallbackReferenceRangeVarianceAllowedRegionRule(allowed: []),
                FallbackReferenceRangeVarianceRatioRangeRule(min: 1.2, max: 1228.0),
                FallbackReferenceRangeVarianceCapacityRangeRule(min: 64, max: 255),
            ]
        )
    }
}
