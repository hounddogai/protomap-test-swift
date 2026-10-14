import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient care gap rule must pass. Check returns its problems, or none.
    protocol LenientCareGapRuleRule {
        func check(_ item: LenientCareGapRule) -> [String]
    }

    final class LenientCareGapRuleNameLengthRule: LenientCareGapRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCareGapRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCareGapRuleVisibleGuardRule: LenientCareGapRuleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LenientCareGapRule) -> [String] {
            if item.visible && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class LenientCareGapRuleCodePrefixRule: LenientCareGapRuleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientCareGapRule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientCareGapRuleRatioRangeRule: LenientCareGapRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCareGapRule) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientCareGapRuleAllowedDescriptionRule: LenientCareGapRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientCareGapRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient care gap rule.
    final class LenientCareGapRuleValidator {
        var rules: [any LenientCareGapRuleRule]

        init(rules: [any LenientCareGapRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCareGapRule) -> [String] {
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

        func requireValid(_ item: LenientCareGapRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCareGapRule]) -> [String: [String]] {
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

    static func defaultLenientCareGapRuleValidator() -> LenientCareGapRuleValidator {
        return LenientCareGapRuleValidator(
            rules: [
                LenientCareGapRuleNameLengthRule(maxLength: 80),
                LenientCareGapRuleVisibleGuardRule(limit: 0.1),
                LenientCareGapRuleCodePrefixRule(prefix: "OPS"),
                LenientCareGapRuleRatioRangeRule(min: 2.1, max: 783.1),
                LenientCareGapRuleAllowedDescriptionRule(allowed: []),
            ]
        )
    }
}
