import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary charge estimate must pass. Check returns its problems, or none.
    protocol PrimaryChargeEstimateRule {
        func check(_ item: PrimaryChargeEstimate) -> [String]
    }

    final class PrimaryChargeEstimateRequiredCodeRule: PrimaryChargeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryChargeEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryChargeEstimateRequiredDescriptionRule: PrimaryChargeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryChargeEstimate) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryChargeEstimateAllowedTitleRule: PrimaryChargeEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryChargeEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    final class PrimaryChargeEstimateVersionRangeRule: PrimaryChargeEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryChargeEstimate) -> [String] {
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

    /// Runs every rule of a primary charge estimate.
    final class PrimaryChargeEstimateValidator {
        var rules: [any PrimaryChargeEstimateRule]

        init(rules: [any PrimaryChargeEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryChargeEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryChargeEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryChargeEstimate]) -> [String: [String]] {
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

    static func defaultPrimaryChargeEstimateValidator() -> PrimaryChargeEstimateValidator {
        return PrimaryChargeEstimateValidator(
            rules: [
                PrimaryChargeEstimateRequiredCodeRule(message: "primary charge estimate needs this field"),
                PrimaryChargeEstimateRequiredDescriptionRule(message: "primary charge estimate needs a value"),
                PrimaryChargeEstimateAllowedTitleRule(allowed: ["default", "legacy", "regional"]),
                PrimaryChargeEstimateVersionRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
