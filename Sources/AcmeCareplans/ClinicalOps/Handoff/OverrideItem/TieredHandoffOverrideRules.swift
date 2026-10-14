import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered handoff override must pass. Check returns its problems, or none.
    protocol TieredHandoffOverrideRule {
        func check(_ item: TieredHandoffOverride) -> [String]
    }

    final class TieredHandoffOverrideTitleLengthRule: TieredHandoffOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredHandoffOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredHandoffOverrideWeightRangeRule: TieredHandoffOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredHandoffOverride) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredHandoffOverrideRequiredProcedureCodeRule: TieredHandoffOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredHandoffOverride) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredHandoffOverrideRequiredTimezoneRule: TieredHandoffOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredHandoffOverride) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered handoff override.
    final class TieredHandoffOverrideValidator {
        var rules: [any TieredHandoffOverrideRule]

        init(rules: [any TieredHandoffOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredHandoffOverride) -> [String] {
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

        func requireValid(_ item: TieredHandoffOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredHandoffOverride]) -> [String: [String]] {
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

    static func defaultTieredHandoffOverrideValidator() -> TieredHandoffOverrideValidator {
        return TieredHandoffOverrideValidator(
            rules: [
                TieredHandoffOverrideTitleLengthRule(maxLength: 3600),
                TieredHandoffOverrideWeightRangeRule(min: 7.1, max: 1566.8),
                TieredHandoffOverrideRequiredProcedureCodeRule(message: "tiered handoff override needs a value"),
                TieredHandoffOverrideRequiredTimezoneRule(message: "tiered handoff override needs a value"),
            ]
        )
    }
}
