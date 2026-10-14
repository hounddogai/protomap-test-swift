import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global order set estimate must pass. Check returns its problems, or none.
    protocol GlobalOrderSetEstimateRule {
        func check(_ item: GlobalOrderSetEstimate) -> [String]
    }

    final class GlobalOrderSetEstimateDosageMgRangeRule: GlobalOrderSetEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalOrderSetEstimate) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalOrderSetEstimateRequiredCodeRule: GlobalOrderSetEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalOrderSetEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalOrderSetEstimateAllowedCodeRule: GlobalOrderSetEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalOrderSetEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class GlobalOrderSetEstimateVersionRangeRule: GlobalOrderSetEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalOrderSetEstimate) -> [String] {
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

    final class GlobalOrderSetEstimateDiscountRangeRule: GlobalOrderSetEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalOrderSetEstimate) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalOrderSetEstimateRequiredTitleRule: GlobalOrderSetEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalOrderSetEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global order set estimate.
    final class GlobalOrderSetEstimateValidator {
        var rules: [any GlobalOrderSetEstimateRule]

        init(rules: [any GlobalOrderSetEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalOrderSetEstimate) -> [String] {
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

        func requireValid(_ item: GlobalOrderSetEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalOrderSetEstimate]) -> [String: [String]] {
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

    static func defaultGlobalOrderSetEstimateValidator() -> GlobalOrderSetEstimateValidator {
        return GlobalOrderSetEstimateValidator(
            rules: [
                GlobalOrderSetEstimateDosageMgRangeRule(min: 6.8, max: 2001.6),
                GlobalOrderSetEstimateRequiredCodeRule(message: "global order set estimate needs an entry"),
                GlobalOrderSetEstimateAllowedCodeRule(allowed: ["strict", "fallback", "tiered"]),
                GlobalOrderSetEstimateVersionRangeRule(min: 16, max: 64),
                GlobalOrderSetEstimateDiscountRangeRule(min: 8.9, max: 1277.8),
                GlobalOrderSetEstimateRequiredTitleRule(message: "global order set estimate needs this field"),
            ]
        )
    }
}
