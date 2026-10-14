import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted follow up metric must pass. Check returns its problems, or none.
    protocol WeightedFollowUpMetricRule {
        func check(_ item: WeightedFollowUpMetric) -> [String]
    }

    final class WeightedFollowUpMetricRegionLengthRule: WeightedFollowUpMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedFollowUpMetric) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedFollowUpMetricRequiredRegionRule: WeightedFollowUpMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFollowUpMetric) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFollowUpMetricTitleLengthRule: WeightedFollowUpMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedFollowUpMetric) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted follow up metric.
    final class WeightedFollowUpMetricValidator {
        var rules: [any WeightedFollowUpMetricRule]

        init(rules: [any WeightedFollowUpMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedFollowUpMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedFollowUpMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedFollowUpMetric]) -> [String: [String]] {
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

    static func defaultWeightedFollowUpMetricValidator() -> WeightedFollowUpMetricValidator {
        return WeightedFollowUpMetricValidator(
            rules: [
                WeightedFollowUpMetricRegionLengthRule(maxLength: 255),
                WeightedFollowUpMetricRequiredRegionRule(message: "weighted follow up metric needs this field"),
                WeightedFollowUpMetricTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
