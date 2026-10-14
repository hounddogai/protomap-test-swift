import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual denial cycle must pass. Check returns its problems, or none.
    protocol ManualDenialCycleRule {
        func check(_ item: ManualDenialCycle) -> [String]
    }

    final class ManualDenialCycleThresholdRangeRule: ManualDenialCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualDenialCycle) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualDenialCycleExpiresAtRangeRule: ManualDenialCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualDenialCycle) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualDenialCycleAllowedCodeRule: ManualDenialCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualDenialCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class ManualDenialCycleApprovedGuardRule: ManualDenialCycleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ManualDenialCycle) -> [String] {
            if item.approved && (item.threshold > limit) {
                return ["threshold \(item.threshold) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ManualDenialCycleCodePrefixRule: ManualDenialCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualDenialCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualDenialCycleRetriesRangeRule: ManualDenialCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualDenialCycle) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual denial cycle.
    final class ManualDenialCycleValidator {
        var rules: [any ManualDenialCycleRule]

        init(rules: [any ManualDenialCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualDenialCycle) -> [String] {
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

        func requireValid(_ item: ManualDenialCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualDenialCycle]) -> [String: [String]] {
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

    static func defaultManualDenialCycleValidator() -> ManualDenialCycleValidator {
        return ManualDenialCycleValidator(
            rules: [
                ManualDenialCycleThresholdRangeRule(min: 7.0, max: 3165.4),
                ManualDenialCycleExpiresAtRangeRule(min: 16, max: 80),
                ManualDenialCycleAllowedCodeRule(allowed: ["strict", "primary"]),
                ManualDenialCycleApprovedGuardRule(limit: 0.3),
                ManualDenialCycleCodePrefixRule(prefix: "ACM"),
                ManualDenialCycleRetriesRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
