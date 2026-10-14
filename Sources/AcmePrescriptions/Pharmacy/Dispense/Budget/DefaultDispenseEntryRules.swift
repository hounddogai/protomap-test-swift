import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default dispense entry must pass. Check returns its problems, or none.
    protocol DefaultDispenseEntryRule {
        func check(_ item: DefaultDispenseEntry) -> [String]
    }

    final class DefaultDispenseEntryAllowedNameRule: DefaultDispenseEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultDispenseEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class DefaultDispenseEntryUpdatedAtRangeRule: DefaultDispenseEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultDispenseEntry) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultDispenseEntryRatioRangeRule: DefaultDispenseEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultDispenseEntry) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultDispenseEntryRequiredCodeRule: DefaultDispenseEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultDispenseEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default dispense entry.
    final class DefaultDispenseEntryValidator {
        var rules: [any DefaultDispenseEntryRule]

        init(rules: [any DefaultDispenseEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultDispenseEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultDispenseEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultDispenseEntry]) -> [String: [String]] {
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

    static func defaultDefaultDispenseEntryValidator() -> DefaultDispenseEntryValidator {
        return DefaultDispenseEntryValidator(
            rules: [
                DefaultDispenseEntryAllowedNameRule(allowed: ["manual", "primary"]),
                DefaultDispenseEntryUpdatedAtRangeRule(min: 32, max: 120),
                DefaultDispenseEntryRatioRangeRule(min: 6.0, max: 1133.1),
                DefaultDispenseEntryRequiredCodeRule(message: "default dispense entry needs this field"),
            ]
        )
    }
}
