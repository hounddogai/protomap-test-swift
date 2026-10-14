import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional study variance must pass. Check returns its problems, or none.
    protocol RegionalStudyVarianceRule {
        func check(_ item: RegionalStudyVariance) -> [String]
    }

    final class RegionalStudyVarianceRequiredTitleRule: RegionalStudyVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalStudyVariance) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalStudyVarianceUpdatedAtRangeRule: RegionalStudyVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalStudyVariance) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalStudyVarianceAllowedTitleRule: RegionalStudyVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalStudyVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    final class RegionalStudyVarianceGraceDaysRangeRule: RegionalStudyVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalStudyVariance) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalStudyVarianceRatioRangeRule: RegionalStudyVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalStudyVariance) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalStudyVarianceCodePrefixRule: RegionalStudyVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalStudyVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional study variance.
    final class RegionalStudyVarianceValidator {
        var rules: [any RegionalStudyVarianceRule]

        init(rules: [any RegionalStudyVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalStudyVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalStudyVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalStudyVariance]) -> [String: [String]] {
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

    static func defaultRegionalStudyVarianceValidator() -> RegionalStudyVarianceValidator {
        return RegionalStudyVarianceValidator(
            rules: [
                RegionalStudyVarianceRequiredTitleRule(message: "regional study variance needs a value"),
                RegionalStudyVarianceUpdatedAtRangeRule(min: 255, max: 3600),
                RegionalStudyVarianceAllowedTitleRule(allowed: ["global", "strict"]),
                RegionalStudyVarianceGraceDaysRangeRule(min: 32, max: 1000),
                RegionalStudyVarianceRatioRangeRule(min: 4.5, max: 4447.4),
                RegionalStudyVarianceCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
