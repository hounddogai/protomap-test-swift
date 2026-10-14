import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial cycle must pass. Check returns its problems, or none.
    protocol DenialCycleRule {
        func check(_ item: DenialCycle) -> [String]
    }

    final class DenialCycleAmountRangeRule: DenialCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialCycle) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DenialCycleAllowedWardRule: DenialCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DenialCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ward)) {
                return ["ward \(item.ward) is below minimum"]
            }
            return []
        }
    }

    final class DenialCycleCodePrefixRule: DenialCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DenialCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DenialCycleRequiredNameRule: DenialCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialCycle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialCycleBudgetRangeRule: DenialCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialCycle) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DenialCycleSequenceRangeRule: DenialCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialCycle) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial cycle.
    final class DenialCycleValidator {
        var rules: [any DenialCycleRule]

        init(rules: [any DenialCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DenialCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialCycle]) -> [String: [String]] {
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

    static func defaultDenialCycleValidator() -> DenialCycleValidator {
        return DenialCycleValidator(
            rules: [
                DenialCycleAmountRangeRule(min: 4.6, max: 3924.0),
                DenialCycleAllowedWardRule(allowed: ["legacy", "seasonal", "strict"]),
                DenialCycleCodePrefixRule(prefix: "REF"),
                DenialCycleRequiredNameRule(message: "denial cycle needs this field"),
                DenialCycleBudgetRangeRule(min: 1.4, max: 289.9),
                DenialCycleSequenceRangeRule(min: 32, max: 80),
            ]
        )
    }
}
