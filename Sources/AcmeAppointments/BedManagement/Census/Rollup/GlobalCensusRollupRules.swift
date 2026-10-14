import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global census rollup must pass. Check returns its problems, or none.
    protocol GlobalCensusRollupRule {
        func check(_ item: GlobalCensusRollup) -> [String]
    }

    final class GlobalCensusRollupCodePrefixRule: GlobalCensusRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalCensusRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalCensusRollupDosageMgRangeRule: GlobalCensusRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCensusRollup) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalCensusRollupApprovedGuardRule: GlobalCensusRollupRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalCensusRollup) -> [String] {
            if item.approved && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a global census rollup.
    final class GlobalCensusRollupValidator {
        var rules: [any GlobalCensusRollupRule]

        init(rules: [any GlobalCensusRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCensusRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalCensusRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCensusRollup]) -> [String: [String]] {
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

    static func defaultGlobalCensusRollupValidator() -> GlobalCensusRollupValidator {
        return GlobalCensusRollupValidator(
            rules: [
                GlobalCensusRollupCodePrefixRule(prefix: "Q"),
                GlobalCensusRollupDosageMgRangeRule(min: 8.1, max: 4528.4),
                GlobalCensusRollupApprovedGuardRule(limit: 86400),
            ]
        )
    }
}
