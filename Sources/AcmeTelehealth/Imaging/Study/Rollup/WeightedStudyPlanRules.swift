import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted study plan must pass. Check returns its problems, or none.
    protocol WeightedStudyPlanRule {
        func check(_ item: WeightedStudyPlan) -> [String]
    }

    final class WeightedStudyPlanAllowedSegmentRule: WeightedStudyPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedStudyPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is missing"]
            }
            return []
        }
    }

    final class WeightedStudyPlanRequiredSummaryRule: WeightedStudyPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedStudyPlan) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedStudyPlanCodeLengthRule: WeightedStudyPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedStudyPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedStudyPlanChannelLengthRule: WeightedStudyPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedStudyPlan) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted study plan.
    final class WeightedStudyPlanValidator {
        var rules: [any WeightedStudyPlanRule]

        init(rules: [any WeightedStudyPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedStudyPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedStudyPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedStudyPlan]) -> [String: [String]] {
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

    static func defaultWeightedStudyPlanValidator() -> WeightedStudyPlanValidator {
        return WeightedStudyPlanValidator(
            rules: [
                WeightedStudyPlanAllowedSegmentRule(allowed: ["rolling"]),
                WeightedStudyPlanRequiredSummaryRule(message: "weighted study plan needs this field"),
                WeightedStudyPlanCodeLengthRule(maxLength: 32),
                WeightedStudyPlanChannelLengthRule(maxLength: 86400),
            ]
        )
    }
}
