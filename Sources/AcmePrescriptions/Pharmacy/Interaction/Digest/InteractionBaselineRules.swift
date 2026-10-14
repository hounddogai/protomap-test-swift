import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction baseline must pass. Check returns its problems, or none.
    protocol InteractionBaselineRule {
        func check(_ item: InteractionBaseline) -> [String]
    }

    final class InteractionBaselineAllowedRegionRule: InteractionBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InteractionBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is not allowed"]
            }
            return []
        }
    }

    final class InteractionBaselineCodeLengthRule: InteractionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionBaselineMarginRangeRule: InteractionBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionBaseline) -> [String] {
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

    final class InteractionBaselineLabelLengthRule: InteractionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionBaselineScoreRangeRule: InteractionBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionBaseline) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionBaselineCodePrefixRule: InteractionBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InteractionBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction baseline.
    final class InteractionBaselineValidator {
        var rules: [any InteractionBaselineRule]

        init(rules: [any InteractionBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionBaseline]) -> [String: [String]] {
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

    static func defaultInteractionBaselineValidator() -> InteractionBaselineValidator {
        return InteractionBaselineValidator(
            rules: [
                InteractionBaselineAllowedRegionRule(allowed: ["capped", "rolling"]),
                InteractionBaselineCodeLengthRule(maxLength: 120),
                InteractionBaselineMarginRangeRule(min: 5.1, max: 2447.4),
                InteractionBaselineLabelLengthRule(maxLength: 64),
                InteractionBaselineScoreRangeRule(min: 4.7, max: 2772.6),
                InteractionBaselineCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
