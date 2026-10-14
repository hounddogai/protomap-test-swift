import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling recall tier must pass. Check returns its problems, or none.
    protocol RollingRecallTierRule {
        func check(_ item: RollingRecallTier) -> [String]
    }

    final class RollingRecallTierNameLengthRule: RollingRecallTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRecallTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingRecallTierVisibleGuardRule: RollingRecallTierRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RollingRecallTier) -> [String] {
            if item.visible && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class RollingRecallTierRatioRangeRule: RollingRecallTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingRecallTier) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingRecallTierCodePrefixRule: RollingRecallTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingRecallTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingRecallTierRequiredCodeRule: RollingRecallTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRecallTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling recall tier.
    final class RollingRecallTierValidator {
        var rules: [any RollingRecallTierRule]

        init(rules: [any RollingRecallTierRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRecallTier) -> [String] {
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

        func requireValid(_ item: RollingRecallTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRecallTier]) -> [String: [String]] {
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

    static func defaultRollingRecallTierValidator() -> RollingRecallTierValidator {
        return RollingRecallTierValidator(
            rules: [
                RollingRecallTierNameLengthRule(maxLength: 3600),
                RollingRecallTierVisibleGuardRule(limit: 4.9),
                RollingRecallTierRatioRangeRule(min: 1.9, max: 1798.3),
                RollingRecallTierCodePrefixRule(prefix: "X"),
                RollingRecallTierRequiredCodeRule(message: "rolling recall tier needs an entry"),
            ]
        )
    }
}
