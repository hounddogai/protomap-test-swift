import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted slot bundle must pass. Check returns its problems, or none.
    protocol WeightedSlotBundleRule {
        func check(_ item: WeightedSlotBundle) -> [String]
    }

    final class WeightedSlotBundleScoreRangeRule: WeightedSlotBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedSlotBundle) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedSlotBundleTitleLengthRule: WeightedSlotBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedSlotBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedSlotBundleRequiredTitleRule: WeightedSlotBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedSlotBundle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedSlotBundleCodePrefixRule: WeightedSlotBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedSlotBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted slot bundle.
    final class WeightedSlotBundleValidator {
        var rules: [any WeightedSlotBundleRule]

        init(rules: [any WeightedSlotBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedSlotBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedSlotBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedSlotBundle]) -> [String: [String]] {
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

    static func defaultWeightedSlotBundleValidator() -> WeightedSlotBundleValidator {
        return WeightedSlotBundleValidator(
            rules: [
                WeightedSlotBundleScoreRangeRule(min: 4.9, max: 521.5),
                WeightedSlotBundleTitleLengthRule(maxLength: 255),
                WeightedSlotBundleRequiredTitleRule(message: "weighted slot bundle needs a value"),
                WeightedSlotBundleCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
