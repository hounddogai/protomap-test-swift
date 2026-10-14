import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling denial entry must pass. Check returns its problems, or none.
    protocol RollingDenialEntryRule {
        func check(_ item: RollingDenialEntry) -> [String]
    }

    final class RollingDenialEntryRequiredLabelRule: RollingDenialEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDenialEntry) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDenialEntryAllowedCodeRule: RollingDenialEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingDenialEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class RollingDenialEntryMaximumRangeRule: RollingDenialEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingDenialEntry) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling denial entry.
    final class RollingDenialEntryValidator {
        var rules: [any RollingDenialEntryRule]

        init(rules: [any RollingDenialEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingDenialEntry) -> [String] {
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

        func requireValid(_ item: RollingDenialEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingDenialEntry]) -> [String: [String]] {
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

    static func defaultRollingDenialEntryValidator() -> RollingDenialEntryValidator {
        return RollingDenialEntryValidator(
            rules: [
                RollingDenialEntryRequiredLabelRule(message: "rolling denial entry needs this field"),
                RollingDenialEntryAllowedCodeRule(allowed: ["legacy", "regional"]),
                RollingDenialEntryMaximumRangeRule(min: 6.4, max: 2690.4),
            ]
        )
    }
}
