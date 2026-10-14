import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered acuity plan entry must pass. Check returns its problems, or none.
    protocol TieredAcuityPlanEntryRule {
        func check(_ item: TieredAcuityPlanEntry) -> [String]
    }

    final class TieredAcuityPlanEntryRequiredCodeRule: TieredAcuityPlanEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAcuityPlanEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAcuityPlanEntryMinimumRangeRule: TieredAcuityPlanEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredAcuityPlanEntry) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredAcuityPlanEntryNameLengthRule: TieredAcuityPlanEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredAcuityPlanEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredAcuityPlanEntryCodePrefixRule: TieredAcuityPlanEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredAcuityPlanEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered acuity plan entry.
    final class TieredAcuityPlanEntryValidator {
        var rules: [any TieredAcuityPlanEntryRule]

        init(rules: [any TieredAcuityPlanEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredAcuityPlanEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredAcuityPlanEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredAcuityPlanEntry]) -> [String: [String]] {
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

    static func defaultTieredAcuityPlanEntryValidator() -> TieredAcuityPlanEntryValidator {
        return TieredAcuityPlanEntryValidator(
            rules: [
                TieredAcuityPlanEntryRequiredCodeRule(message: "tiered acuity plan entry needs this field"),
                TieredAcuityPlanEntryMinimumRangeRule(min: 2.1, max: 4879.8),
                TieredAcuityPlanEntryNameLengthRule(maxLength: 1000),
                TieredAcuityPlanEntryCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
