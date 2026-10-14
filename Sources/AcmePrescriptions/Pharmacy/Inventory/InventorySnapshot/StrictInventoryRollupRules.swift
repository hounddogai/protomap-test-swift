import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a strict inventory rollup must pass. Check returns its problems, or none.
    protocol StrictInventoryRollupRule {
        func check(_ item: StrictInventoryRollup) -> [String]
    }

    final class StrictInventoryRollupScoreRangeRule: StrictInventoryRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictInventoryRollup) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictInventoryRollupCodePrefixRule: StrictInventoryRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictInventoryRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictInventoryRollupRequiredTitleRule: StrictInventoryRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictInventoryRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict inventory rollup.
    final class StrictInventoryRollupValidator {
        var rules: [any StrictInventoryRollupRule]

        init(rules: [any StrictInventoryRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictInventoryRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictInventoryRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictInventoryRollup]) -> [String: [String]] {
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

    static func defaultStrictInventoryRollupValidator() -> StrictInventoryRollupValidator {
        return StrictInventoryRollupValidator(
            rules: [
                StrictInventoryRollupScoreRangeRule(min: 2.0, max: 4162.5),
                StrictInventoryRollupCodePrefixRule(prefix: "REF"),
                StrictInventoryRollupRequiredTitleRule(message: "strict inventory rollup needs an entry"),
            ]
        )
    }
}
