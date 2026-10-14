import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global task override must pass. Check returns its problems, or none.
    protocol GlobalTaskOverrideRule {
        func check(_ item: GlobalTaskOverride) -> [String]
    }

    final class GlobalTaskOverrideAttemptsRangeRule: GlobalTaskOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalTaskOverride) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalTaskOverrideRequiredSpecialtyRule: GlobalTaskOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalTaskOverride) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalTaskOverrideDosageMgRangeRule: GlobalTaskOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalTaskOverride) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalTaskOverrideRequiredNameRule: GlobalTaskOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalTaskOverride) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global task override.
    final class GlobalTaskOverrideValidator {
        var rules: [any GlobalTaskOverrideRule]

        init(rules: [any GlobalTaskOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalTaskOverride) -> [String] {
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

        func requireValid(_ item: GlobalTaskOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalTaskOverride]) -> [String: [String]] {
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

    static func defaultGlobalTaskOverrideValidator() -> GlobalTaskOverrideValidator {
        return GlobalTaskOverrideValidator(
            rules: [
                GlobalTaskOverrideAttemptsRangeRule(min: 32, max: 32),
                GlobalTaskOverrideRequiredSpecialtyRule(message: "global task override needs an entry"),
                GlobalTaskOverrideDosageMgRangeRule(min: 1.4, max: 4165.8),
                GlobalTaskOverrideRequiredNameRule(message: "global task override needs an entry"),
            ]
        )
    }
}
