import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped denial target must pass. Check returns its problems, or none.
    protocol CappedDenialTargetRule {
        func check(_ item: CappedDenialTarget) -> [String]
    }

    final class CappedDenialTargetRequiredNameRule: CappedDenialTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDenialTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedDenialTargetCeilingRangeRule: CappedDenialTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedDenialTarget) -> [String] {
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

    final class CappedDenialTargetAllowedRegionRule: CappedDenialTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedDenialTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is too long"]
            }
            return []
        }
    }

    final class CappedDenialTargetGraceDaysRangeRule: CappedDenialTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedDenialTarget) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedDenialTargetRequiredRegionRule: CappedDenialTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedDenialTarget) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped denial target.
    final class CappedDenialTargetValidator {
        var rules: [any CappedDenialTargetRule]

        init(rules: [any CappedDenialTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedDenialTarget) -> [String] {
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

        func requireValid(_ item: CappedDenialTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedDenialTarget]) -> [String: [String]] {
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

    static func defaultCappedDenialTargetValidator() -> CappedDenialTargetValidator {
        return CappedDenialTargetValidator(
            rules: [
                CappedDenialTargetRequiredNameRule(message: "capped denial target needs a value"),
                CappedDenialTargetCeilingRangeRule(min: 4.7, max: 3250.3),
                CappedDenialTargetAllowedRegionRule(allowed: ["pending"]),
                CappedDenialTargetGraceDaysRangeRule(min: 1000, max: 3600),
                CappedDenialTargetRequiredRegionRule(message: "capped denial target needs this field"),
            ]
        )
    }
}
