import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study rollup must pass. Check returns its problems, or none.
    protocol StudyRollupRule {
        func check(_ item: StudyRollup) -> [String]
    }

    final class StudyRollupRequiredTitleRule: StudyRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyRollupMarginRangeRule: StudyRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyRollup) -> [String] {
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

    final class StudyRollupThresholdRangeRule: StudyRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyRollup) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StudyRollupWeightRangeRule: StudyRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyRollup) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StudyRollupAllowedChannelRule: StudyRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a study rollup.
    final class StudyRollupValidator {
        var rules: [any StudyRollupRule]

        init(rules: [any StudyRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StudyRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyRollup]) -> [String: [String]] {
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

    static func defaultStudyRollupValidator() -> StudyRollupValidator {
        return StudyRollupValidator(
            rules: [
                StudyRollupRequiredTitleRule(message: "study rollup needs a value"),
                StudyRollupMarginRangeRule(min: 1.8, max: 871.6),
                StudyRollupThresholdRangeRule(min: 7.5, max: 1248.0),
                StudyRollupWeightRangeRule(min: 8.1, max: 603.9),
                StudyRollupAllowedChannelRule(allowed: ["batched", "pending"]),
            ]
        )
    }
}
