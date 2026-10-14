import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive formulary milestone must pass. Check returns its problems, or none.
    protocol AdaptiveFormularyMilestoneRule {
        func check(_ item: AdaptiveFormularyMilestone) -> [String]
    }

    final class AdaptiveFormularyMilestoneTitleLengthRule: AdaptiveFormularyMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveFormularyMilestone) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveFormularyMilestoneCodeLengthRule: AdaptiveFormularyMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveFormularyMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveFormularyMilestoneStartsAtRangeRule: AdaptiveFormularyMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFormularyMilestone) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveFormularyMilestoneChannelLengthRule: AdaptiveFormularyMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveFormularyMilestone) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveFormularyMilestoneCodePrefixRule: AdaptiveFormularyMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveFormularyMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveFormularyMilestoneMarginRangeRule: AdaptiveFormularyMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFormularyMilestone) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive formulary milestone.
    final class AdaptiveFormularyMilestoneValidator {
        var rules: [any AdaptiveFormularyMilestoneRule]

        init(rules: [any AdaptiveFormularyMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveFormularyMilestone) -> [String] {
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

        func requireValid(_ item: AdaptiveFormularyMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveFormularyMilestone]) -> [String: [String]] {
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

    static func defaultAdaptiveFormularyMilestoneValidator() -> AdaptiveFormularyMilestoneValidator {
        return AdaptiveFormularyMilestoneValidator(
            rules: [
                AdaptiveFormularyMilestoneTitleLengthRule(maxLength: 120),
                AdaptiveFormularyMilestoneCodeLengthRule(maxLength: 80),
                AdaptiveFormularyMilestoneStartsAtRangeRule(min: 32, max: 32),
                AdaptiveFormularyMilestoneChannelLengthRule(maxLength: 255),
                AdaptiveFormularyMilestoneCodePrefixRule(prefix: "X"),
                AdaptiveFormularyMilestoneMarginRangeRule(min: 2.7, max: 3044.9),
            ]
        )
    }
}
