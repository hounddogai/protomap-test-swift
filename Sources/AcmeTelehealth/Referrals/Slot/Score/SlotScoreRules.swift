import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot score must pass. Check returns its problems, or none.
    protocol SlotScoreRule {
        func check(_ item: SlotScore) -> [String]
    }

    final class SlotScoreRequiredCodeRule: SlotScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotScoreCodePrefixRule: SlotScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SlotScoreRequiredLocaleRule: SlotScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotScore) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotScoreAllowedCodeRule: SlotScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SlotScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class SlotScoreThresholdRangeRule: SlotScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotScore) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot score.
    final class SlotScoreValidator {
        var rules: [any SlotScoreRule]

        init(rules: [any SlotScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotScore) -> [String] {
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

        func requireValid(_ item: SlotScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotScore]) -> [String: [String]] {
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

    static func defaultSlotScoreValidator() -> SlotScoreValidator {
        return SlotScoreValidator(
            rules: [
                SlotScoreRequiredCodeRule(message: "slot score needs this field"),
                SlotScoreCodePrefixRule(prefix: "ACM"),
                SlotScoreRequiredLocaleRule(message: "slot score needs a value"),
                SlotScoreAllowedCodeRule(allowed: ["batched", "lenient"]),
                SlotScoreThresholdRangeRule(min: 3.8, max: 2079.7),
            ]
        )
    }
}
