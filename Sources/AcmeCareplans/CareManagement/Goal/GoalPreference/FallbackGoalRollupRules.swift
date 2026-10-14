import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback goal rollup must pass. Check returns its problems, or none.
    protocol FallbackGoalRollupRule {
        func check(_ item: FallbackGoalRollup) -> [String]
    }

    final class FallbackGoalRollupVisibleGuardRule: FallbackGoalRollupRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FallbackGoalRollup) -> [String] {
            if item.visible && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class FallbackGoalRollupCodeLengthRule: FallbackGoalRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackGoalRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackGoalRollupCreatedAtRangeRule: FallbackGoalRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackGoalRollup) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackGoalRollupExternalRefLengthRule: FallbackGoalRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackGoalRollup) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackGoalRollupCodePrefixRule: FallbackGoalRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackGoalRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackGoalRollupNameLengthRule: FallbackGoalRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackGoalRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback goal rollup.
    final class FallbackGoalRollupValidator {
        var rules: [any FallbackGoalRollupRule]

        init(rules: [any FallbackGoalRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackGoalRollup) -> [String] {
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

        func requireValid(_ item: FallbackGoalRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackGoalRollup]) -> [String: [String]] {
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

    static func defaultFallbackGoalRollupValidator() -> FallbackGoalRollupValidator {
        return FallbackGoalRollupValidator(
            rules: [
                FallbackGoalRollupVisibleGuardRule(limit: 2.9),
                FallbackGoalRollupCodeLengthRule(maxLength: 16),
                FallbackGoalRollupCreatedAtRangeRule(min: 120, max: 255),
                FallbackGoalRollupExternalRefLengthRule(maxLength: 255),
                FallbackGoalRollupCodePrefixRule(prefix: "OPS"),
                FallbackGoalRollupNameLengthRule(maxLength: 16),
            ]
        )
    }
}
