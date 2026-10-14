import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a weighted acuity plan estimate must pass. Check returns its problems, or none.
    protocol WeightedAcuityPlanEstimateRule {
        func check(_ item: WeightedAcuityPlanEstimate) -> [String]
    }

    final class WeightedAcuityPlanEstimateNameLengthRule: WeightedAcuityPlanEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAcuityPlanEstimate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAcuityPlanEstimateRequiredNameRule: WeightedAcuityPlanEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAcuityPlanEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedAcuityPlanEstimateRequiredReviewerRule: WeightedAcuityPlanEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAcuityPlanEstimate) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted acuity plan estimate.
    final class WeightedAcuityPlanEstimateValidator {
        var rules: [any WeightedAcuityPlanEstimateRule]

        init(rules: [any WeightedAcuityPlanEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedAcuityPlanEstimate) -> [String] {
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

        func requireValid(_ item: WeightedAcuityPlanEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedAcuityPlanEstimate]) -> [String: [String]] {
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

    static func defaultWeightedAcuityPlanEstimateValidator() -> WeightedAcuityPlanEstimateValidator {
        return WeightedAcuityPlanEstimateValidator(
            rules: [
                WeightedAcuityPlanEstimateNameLengthRule(maxLength: 86400),
                WeightedAcuityPlanEstimateRequiredNameRule(message: "weighted acuity plan estimate needs this field"),
                WeightedAcuityPlanEstimateRequiredReviewerRule(
                    message: "weighted acuity plan estimate needs this field"
                ),
            ]
        )
    }
}
