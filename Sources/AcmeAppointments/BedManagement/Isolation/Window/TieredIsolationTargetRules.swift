import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a tiered isolation target must pass. Check returns its problems, or none.
    protocol TieredIsolationTargetRule {
        func check(_ item: TieredIsolationTarget) -> [String]
    }

    final class TieredIsolationTargetRequiredCodeRule: TieredIsolationTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredIsolationTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredIsolationTargetAcuityRangeRule: TieredIsolationTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredIsolationTarget) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredIsolationTargetAllowedUnitRule: TieredIsolationTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredIsolationTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is stale"]
            }
            return []
        }
    }

    final class TieredIsolationTargetCodePrefixRule: TieredIsolationTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredIsolationTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredIsolationTargetRequiredNameRule: TieredIsolationTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredIsolationTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered isolation target.
    final class TieredIsolationTargetValidator {
        var rules: [any TieredIsolationTargetRule]

        init(rules: [any TieredIsolationTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredIsolationTarget) -> [String] {
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

        func requireValid(_ item: TieredIsolationTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredIsolationTarget]) -> [String: [String]] {
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

    static func defaultTieredIsolationTargetValidator() -> TieredIsolationTargetValidator {
        return TieredIsolationTargetValidator(
            rules: [
                TieredIsolationTargetRequiredCodeRule(message: "tiered isolation target needs an entry"),
                TieredIsolationTargetAcuityRangeRule(min: 1000, max: 86400),
                TieredIsolationTargetAllowedUnitRule(allowed: []),
                TieredIsolationTargetCodePrefixRule(prefix: "X"),
                TieredIsolationTargetRequiredNameRule(message: "tiered isolation target needs this field"),
            ]
        )
    }
}
