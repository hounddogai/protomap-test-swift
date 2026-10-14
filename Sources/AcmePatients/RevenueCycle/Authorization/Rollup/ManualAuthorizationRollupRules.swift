import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual authorization rollup must pass. Check returns its problems, or none.
    protocol ManualAuthorizationRollupRule {
        func check(_ item: ManualAuthorizationRollup) -> [String]
    }

    final class ManualAuthorizationRollupRequiredCategoryRule: ManualAuthorizationRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAuthorizationRollup) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualAuthorizationRollupApprovedGuardRule: ManualAuthorizationRollupRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ManualAuthorizationRollup) -> [String] {
            if item.approved && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ManualAuthorizationRollupMaximumRangeRule: ManualAuthorizationRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualAuthorizationRollup) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualAuthorizationRollupLabelLengthRule: ManualAuthorizationRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualAuthorizationRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualAuthorizationRollupAllowedChannelRule: ManualAuthorizationRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualAuthorizationRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is blocked"]
            }
            return []
        }
    }

    final class ManualAuthorizationRollupRequiredCodeRule: ManualAuthorizationRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualAuthorizationRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual authorization rollup.
    final class ManualAuthorizationRollupValidator {
        var rules: [any ManualAuthorizationRollupRule]

        init(rules: [any ManualAuthorizationRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualAuthorizationRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualAuthorizationRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualAuthorizationRollup]) -> [String: [String]] {
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

    static func defaultManualAuthorizationRollupValidator() -> ManualAuthorizationRollupValidator {
        return ManualAuthorizationRollupValidator(
            rules: [
                ManualAuthorizationRollupRequiredCategoryRule(message: "manual authorization rollup needs an entry"),
                ManualAuthorizationRollupApprovedGuardRule(limit: 7.8),
                ManualAuthorizationRollupMaximumRangeRule(min: 2.7, max: 1514.6),
                ManualAuthorizationRollupLabelLengthRule(maxLength: 16),
                ManualAuthorizationRollupAllowedChannelRule(allowed: ["pending", "adaptive", "pending"]),
                ManualAuthorizationRollupRequiredCodeRule(message: "manual authorization rollup needs an entry"),
            ]
        )
    }
}
