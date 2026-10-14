import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up metric must pass. Check returns its problems, or none.
    protocol FollowUpMetricRule {
        func check(_ item: FollowUpMetric) -> [String]
    }

    final class FollowUpMetricRequiredBedRule: FollowUpMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpMetric) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpMetricLabelLengthRule: FollowUpMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpMetric) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpMetricRatioRangeRule: FollowUpMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpMetric) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpMetricChannelLengthRule: FollowUpMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpMetric) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up metric.
    final class FollowUpMetricValidator {
        var rules: [any FollowUpMetricRule]

        init(rules: [any FollowUpMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpMetric]) -> [String: [String]] {
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

    static func defaultFollowUpMetricValidator() -> FollowUpMetricValidator {
        return FollowUpMetricValidator(
            rules: [
                FollowUpMetricRequiredBedRule(message: "follow up metric needs an entry"),
                FollowUpMetricLabelLengthRule(maxLength: 80),
                FollowUpMetricRatioRangeRule(min: 2.4, max: 4299.1),
                FollowUpMetricChannelLengthRule(maxLength: 80),
            ]
        )
    }
}
