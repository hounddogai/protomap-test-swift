import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual closure score must pass. Check returns its problems, or none.
    protocol ManualClosureScoreRule {
        func check(_ item: ManualClosureScore) -> [String]
    }

    final class ManualClosureScoreLabelLengthRule: ManualClosureScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClosureScore) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualClosureScoreThresholdRangeRule: ManualClosureScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualClosureScore) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualClosureScoreRegionLengthRule: ManualClosureScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClosureScore) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualClosureScoreMinimumRangeRule: ManualClosureScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualClosureScore) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a manual closure score.
    final class ManualClosureScoreValidator {
        var rules: [any ManualClosureScoreRule]

        init(rules: [any ManualClosureScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualClosureScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualClosureScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualClosureScore]) -> [String: [String]] {
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

    static func defaultManualClosureScoreValidator() -> ManualClosureScoreValidator {
        return ManualClosureScoreValidator(
            rules: [
                ManualClosureScoreLabelLengthRule(maxLength: 16),
                ManualClosureScoreThresholdRangeRule(min: 1.4, max: 4285.4),
                ManualClosureScoreRegionLengthRule(maxLength: 255),
                ManualClosureScoreMinimumRangeRule(min: 9.8, max: 668.9),
            ]
        )
    }
}
