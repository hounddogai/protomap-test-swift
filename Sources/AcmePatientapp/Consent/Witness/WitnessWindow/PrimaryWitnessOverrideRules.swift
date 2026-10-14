import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary witness override must pass. Check returns its problems, or none.
    protocol PrimaryWitnessOverrideRule {
        func check(_ item: PrimaryWitnessOverride) -> [String]
    }

    final class PrimaryWitnessOverrideRequiredSpecialtyRule: PrimaryWitnessOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryWitnessOverride) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryWitnessOverrideCeilingRangeRule: PrimaryWitnessOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryWitnessOverride) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryWitnessOverrideDurationMinutesRangeRule: PrimaryWitnessOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryWitnessOverride) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryWitnessOverrideRequiredCodeRule: PrimaryWitnessOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryWitnessOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryWitnessOverrideAllowedUnitRule: PrimaryWitnessOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryWitnessOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a primary witness override.
    final class PrimaryWitnessOverrideValidator {
        var rules: [any PrimaryWitnessOverrideRule]

        init(rules: [any PrimaryWitnessOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryWitnessOverride) -> [String] {
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

        func requireValid(_ item: PrimaryWitnessOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryWitnessOverride]) -> [String: [String]] {
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

    static func defaultPrimaryWitnessOverrideValidator() -> PrimaryWitnessOverrideValidator {
        return PrimaryWitnessOverrideValidator(
            rules: [
                PrimaryWitnessOverrideRequiredSpecialtyRule(message: "primary witness override needs this field"),
                PrimaryWitnessOverrideCeilingRangeRule(min: 3.0, max: 2292.9),
                PrimaryWitnessOverrideDurationMinutesRangeRule(min: 32, max: 120),
                PrimaryWitnessOverrideRequiredCodeRule(message: "primary witness override needs an entry"),
                PrimaryWitnessOverrideAllowedUnitRule(allowed: ["primary", "rolling", "pending"]),
            ]
        )
    }
}
