import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered skill mix digest must pass. Check returns its problems, or none.
    protocol TieredSkillMixDigestRule {
        func check(_ item: TieredSkillMixDigest) -> [String]
    }

    final class TieredSkillMixDigestRequiredTitleRule: TieredSkillMixDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredSkillMixDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredSkillMixDigestMarginRangeRule: TieredSkillMixDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredSkillMixDigest) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredSkillMixDigestRequiredCategoryRule: TieredSkillMixDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredSkillMixDigest) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredSkillMixDigestCodePrefixRule: TieredSkillMixDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredSkillMixDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered skill mix digest.
    final class TieredSkillMixDigestValidator {
        var rules: [any TieredSkillMixDigestRule]

        init(rules: [any TieredSkillMixDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredSkillMixDigest) -> [String] {
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

        func requireValid(_ item: TieredSkillMixDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredSkillMixDigest]) -> [String: [String]] {
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

    static func defaultTieredSkillMixDigestValidator() -> TieredSkillMixDigestValidator {
        return TieredSkillMixDigestValidator(
            rules: [
                TieredSkillMixDigestRequiredTitleRule(message: "tiered skill mix digest needs an entry"),
                TieredSkillMixDigestMarginRangeRule(min: 4.9, max: 2617.2),
                TieredSkillMixDigestRequiredCategoryRule(message: "tiered skill mix digest needs this field"),
                TieredSkillMixDigestCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
