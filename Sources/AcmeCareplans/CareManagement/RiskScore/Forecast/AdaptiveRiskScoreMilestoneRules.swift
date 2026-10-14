import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive risk score milestone must pass. Check returns its problems, or none.
    protocol AdaptiveRiskScoreMilestoneRule {
        func check(_ item: AdaptiveRiskScoreMilestone) -> [String]
    }

    final class AdaptiveRiskScoreMilestoneCountryLengthRule: AdaptiveRiskScoreMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveRiskScoreMilestone) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreMilestoneCodePrefixRule: AdaptiveRiskScoreMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveRiskScoreMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveRiskScoreMilestoneCeilingRangeRule: AdaptiveRiskScoreMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveRiskScoreMilestone) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive risk score milestone.
    final class AdaptiveRiskScoreMilestoneValidator {
        var rules: [any AdaptiveRiskScoreMilestoneRule]

        init(rules: [any AdaptiveRiskScoreMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveRiskScoreMilestone) -> [String] {
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

        func requireValid(_ item: AdaptiveRiskScoreMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveRiskScoreMilestone]) -> [String: [String]] {
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

    static func defaultAdaptiveRiskScoreMilestoneValidator() -> AdaptiveRiskScoreMilestoneValidator {
        return AdaptiveRiskScoreMilestoneValidator(
            rules: [
                AdaptiveRiskScoreMilestoneCountryLengthRule(maxLength: 16),
                AdaptiveRiskScoreMilestoneCodePrefixRule(prefix: "REF"),
                AdaptiveRiskScoreMilestoneCeilingRangeRule(min: 3.3, max: 4712.7),
            ]
        )
    }
}
