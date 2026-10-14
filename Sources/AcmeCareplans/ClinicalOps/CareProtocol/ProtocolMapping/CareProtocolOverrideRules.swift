import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol override must pass. Check returns its problems, or none.
    protocol CareProtocolOverrideRule {
        func check(_ item: CareProtocolOverride) -> [String]
    }

    final class CareProtocolOverrideTitleLengthRule: CareProtocolOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolOverrideScoreRangeRule: CareProtocolOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolOverride) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolOverrideRateRangeRule: CareProtocolOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolOverride) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolOverrideRatioRangeRule: CareProtocolOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolOverride) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolOverrideAllowedTitleRule: CareProtocolOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol override.
    final class CareProtocolOverrideValidator {
        var rules: [any CareProtocolOverrideRule]

        init(rules: [any CareProtocolOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolOverride) -> [String] {
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

        func requireValid(_ item: CareProtocolOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolOverride]) -> [String: [String]] {
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

    static func defaultCareProtocolOverrideValidator() -> CareProtocolOverrideValidator {
        return CareProtocolOverrideValidator(
            rules: [
                CareProtocolOverrideTitleLengthRule(maxLength: 3600),
                CareProtocolOverrideScoreRangeRule(min: 4.2, max: 4319.4),
                CareProtocolOverrideRateRangeRule(min: 8.6, max: 1076.1),
                CareProtocolOverrideRatioRangeRule(min: 3.6, max: 3566.8),
                CareProtocolOverrideAllowedTitleRule(allowed: ["rolling"]),
            ]
        )
    }
}
