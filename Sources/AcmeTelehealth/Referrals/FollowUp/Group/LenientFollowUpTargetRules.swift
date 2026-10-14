import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a lenient follow up target must pass. Check returns its problems, or none.
    protocol LenientFollowUpTargetRule {
        func check(_ item: LenientFollowUpTarget) -> [String]
    }

    final class LenientFollowUpTargetMarginRangeRule: LenientFollowUpTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientFollowUpTarget) -> [String] {
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

    final class LenientFollowUpTargetVersionRangeRule: LenientFollowUpTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientFollowUpTarget) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientFollowUpTargetUpdatedAtRangeRule: LenientFollowUpTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientFollowUpTarget) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientFollowUpTargetCodePrefixRule: LenientFollowUpTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientFollowUpTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient follow up target.
    final class LenientFollowUpTargetValidator {
        var rules: [any LenientFollowUpTargetRule]

        init(rules: [any LenientFollowUpTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientFollowUpTarget) -> [String] {
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

        func requireValid(_ item: LenientFollowUpTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientFollowUpTarget]) -> [String: [String]] {
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

    static func defaultLenientFollowUpTargetValidator() -> LenientFollowUpTargetValidator {
        return LenientFollowUpTargetValidator(
            rules: [
                LenientFollowUpTargetMarginRangeRule(min: 9.4, max: 1975.1),
                LenientFollowUpTargetVersionRangeRule(min: 32, max: 64),
                LenientFollowUpTargetUpdatedAtRangeRule(min: 64, max: 3600),
                LenientFollowUpTargetCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
