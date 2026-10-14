import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal priority variance must pass. Check returns its problems, or none.
    protocol SeasonalPriorityVarianceRule {
        func check(_ item: SeasonalPriorityVariance) -> [String]
    }

    final class SeasonalPriorityVarianceCodeLengthRule: SeasonalPriorityVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalPriorityVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalPriorityVarianceCopayRangeRule: SeasonalPriorityVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalPriorityVariance) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalPriorityVarianceCodePrefixRule: SeasonalPriorityVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalPriorityVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalPriorityVarianceCeilingRangeRule: SeasonalPriorityVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalPriorityVariance) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalPriorityVarianceChannelLengthRule: SeasonalPriorityVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalPriorityVariance) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalPriorityVarianceTitleLengthRule: SeasonalPriorityVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalPriorityVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal priority variance.
    final class SeasonalPriorityVarianceValidator {
        var rules: [any SeasonalPriorityVarianceRule]

        init(rules: [any SeasonalPriorityVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalPriorityVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalPriorityVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalPriorityVariance]) -> [String: [String]] {
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

    static func defaultSeasonalPriorityVarianceValidator() -> SeasonalPriorityVarianceValidator {
        return SeasonalPriorityVarianceValidator(
            rules: [
                SeasonalPriorityVarianceCodeLengthRule(maxLength: 32),
                SeasonalPriorityVarianceCopayRangeRule(min: 0.9, max: 3186.6),
                SeasonalPriorityVarianceCodePrefixRule(prefix: "Q"),
                SeasonalPriorityVarianceCeilingRangeRule(min: 3.0, max: 2336.1),
                SeasonalPriorityVarianceChannelLengthRule(maxLength: 1000),
                SeasonalPriorityVarianceTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
