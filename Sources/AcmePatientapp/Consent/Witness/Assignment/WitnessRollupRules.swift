import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness rollup must pass. Check returns its problems, or none.
    protocol WitnessRollupRule {
        func check(_ item: WitnessRollup) -> [String]
    }

    final class WitnessRollupAllowedCodeRule: WitnessRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class WitnessRollupRequiredTitleRule: WitnessRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessRollupCodePrefixRule: WitnessRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WitnessRollupRequiredCodeRule: WitnessRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness rollup.
    final class WitnessRollupValidator {
        var rules: [any WitnessRollupRule]

        init(rules: [any WitnessRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessRollup) -> [String] {
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

        func requireValid(_ item: WitnessRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessRollup]) -> [String: [String]] {
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

    static func defaultWitnessRollupValidator() -> WitnessRollupValidator {
        return WitnessRollupValidator(
            rules: [
                WitnessRollupAllowedCodeRule(allowed: ["batched"]),
                WitnessRollupRequiredTitleRule(message: "witness rollup needs a value"),
                WitnessRollupCodePrefixRule(prefix: "OPS"),
                WitnessRollupRequiredCodeRule(message: "witness rollup needs a value"),
            ]
        )
    }
}
