import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive reference range milestone must pass. Check returns its problems, or none.
    protocol AdaptiveReferenceRangeMilestoneRule {
        func check(_ item: AdaptiveReferenceRangeMilestone) -> [String]
    }

    final class AdaptiveReferenceRangeMilestoneCodePrefixRule: AdaptiveReferenceRangeMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveReferenceRangeMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveReferenceRangeMilestoneRequiredExternalRefRule: AdaptiveReferenceRangeMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveReferenceRangeMilestone) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveReferenceRangeMilestoneWeightRangeRule: AdaptiveReferenceRangeMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveReferenceRangeMilestone) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive reference range milestone.
    final class AdaptiveReferenceRangeMilestoneValidator {
        var rules: [any AdaptiveReferenceRangeMilestoneRule]

        init(rules: [any AdaptiveReferenceRangeMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveReferenceRangeMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveReferenceRangeMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveReferenceRangeMilestone]) -> [String: [String]] {
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

    static func defaultAdaptiveReferenceRangeMilestoneValidator() -> AdaptiveReferenceRangeMilestoneValidator {
        return AdaptiveReferenceRangeMilestoneValidator(
            rules: [
                AdaptiveReferenceRangeMilestoneCodePrefixRule(prefix: "Q"),
                AdaptiveReferenceRangeMilestoneRequiredExternalRefRule(
                    message: "adaptive reference range milestone needs an entry"
                ),
                AdaptiveReferenceRangeMilestoneWeightRangeRule(min: 0.6, max: 3570.2),
            ]
        )
    }
}
