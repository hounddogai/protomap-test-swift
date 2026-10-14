import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual witness rollup must pass. Check returns its problems, or none.
    protocol ManualWitnessRollupRule {
        func check(_ item: ManualWitnessRollup) -> [String]
    }

    final class ManualWitnessRollupWindowDaysRangeRule: ManualWitnessRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualWitnessRollup) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualWitnessRollupAllowedNameRule: ManualWitnessRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualWitnessRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class ManualWitnessRollupVersionRangeRule: ManualWitnessRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualWitnessRollup) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualWitnessRollupCodePrefixRule: ManualWitnessRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualWitnessRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualWitnessRollupRequiredCodeRule: ManualWitnessRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualWitnessRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual witness rollup.
    final class ManualWitnessRollupValidator {
        var rules: [any ManualWitnessRollupRule]

        init(rules: [any ManualWitnessRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualWitnessRollup) -> [String] {
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

        func requireValid(_ item: ManualWitnessRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualWitnessRollup]) -> [String: [String]] {
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

    static func defaultManualWitnessRollupValidator() -> ManualWitnessRollupValidator {
        return ManualWitnessRollupValidator(
            rules: [
                ManualWitnessRollupWindowDaysRangeRule(min: 255, max: 86400),
                ManualWitnessRollupAllowedNameRule(allowed: ["legacy", "adaptive"]),
                ManualWitnessRollupVersionRangeRule(min: 1000, max: 3600),
                ManualWitnessRollupCodePrefixRule(prefix: "X"),
                ManualWitnessRollupRequiredCodeRule(message: "manual witness rollup needs an entry"),
            ]
        )
    }
}
