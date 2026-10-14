import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered acuity plan override must pass. Check returns its problems, or none.
    protocol TieredAcuityPlanOverrideRule {
        func check(_ item: TieredAcuityPlanOverride) -> [String]
    }

    final class TieredAcuityPlanOverrideRequiredNameRule: TieredAcuityPlanOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAcuityPlanOverride) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAcuityPlanOverrideSourceLengthRule: TieredAcuityPlanOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredAcuityPlanOverride) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredAcuityPlanOverrideRateRangeRule: TieredAcuityPlanOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredAcuityPlanOverride) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredAcuityPlanOverrideCodePrefixRule: TieredAcuityPlanOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredAcuityPlanOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered acuity plan override.
    final class TieredAcuityPlanOverrideValidator {
        var rules: [any TieredAcuityPlanOverrideRule]

        init(rules: [any TieredAcuityPlanOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredAcuityPlanOverride) -> [String] {
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

        func requireValid(_ item: TieredAcuityPlanOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredAcuityPlanOverride]) -> [String: [String]] {
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

    static func defaultTieredAcuityPlanOverrideValidator() -> TieredAcuityPlanOverrideValidator {
        return TieredAcuityPlanOverrideValidator(
            rules: [
                TieredAcuityPlanOverrideRequiredNameRule(message: "tiered acuity plan override needs this field"),
                TieredAcuityPlanOverrideSourceLengthRule(maxLength: 32),
                TieredAcuityPlanOverrideRateRangeRule(min: 6.3, max: 1614.3),
                TieredAcuityPlanOverrideCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
