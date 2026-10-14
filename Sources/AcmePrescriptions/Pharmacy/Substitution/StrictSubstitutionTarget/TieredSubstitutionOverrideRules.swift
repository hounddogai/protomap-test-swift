import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a tiered substitution override must pass. Check returns its problems, or none.
    protocol TieredSubstitutionOverrideRule {
        func check(_ item: TieredSubstitutionOverride) -> [String]
    }

    final class TieredSubstitutionOverrideChannelLengthRule: TieredSubstitutionOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSubstitutionOverride) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSubstitutionOverrideQuantityRangeRule: TieredSubstitutionOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredSubstitutionOverride) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredSubstitutionOverrideLimitRangeRule: TieredSubstitutionOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredSubstitutionOverride) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredSubstitutionOverrideApprovedGuardRule: TieredSubstitutionOverrideRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredSubstitutionOverride) -> [String] {
            if item.approved && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered substitution override.
    final class TieredSubstitutionOverrideValidator {
        var rules: [any TieredSubstitutionOverrideRule]

        init(rules: [any TieredSubstitutionOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredSubstitutionOverride) -> [String] {
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

        func requireValid(_ item: TieredSubstitutionOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredSubstitutionOverride]) -> [String: [String]] {
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

    static func defaultTieredSubstitutionOverrideValidator() -> TieredSubstitutionOverrideValidator {
        return TieredSubstitutionOverrideValidator(
            rules: [
                TieredSubstitutionOverrideChannelLengthRule(maxLength: 255),
                TieredSubstitutionOverrideQuantityRangeRule(min: 16, max: 32),
                TieredSubstitutionOverrideLimitRangeRule(min: 1000, max: 1000),
                TieredSubstitutionOverrideApprovedGuardRule(limit: 32),
            ]
        )
    }
}
