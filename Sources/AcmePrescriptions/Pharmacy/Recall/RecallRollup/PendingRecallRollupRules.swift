import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending recall rollup must pass. Check returns its problems, or none.
    protocol PendingRecallRollupRule {
        func check(_ item: PendingRecallRollup) -> [String]
    }

    final class PendingRecallRollupCodePrefixRule: PendingRecallRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingRecallRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingRecallRollupAllowedCodeRule: PendingRecallRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingRecallRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class PendingRecallRollupRequiredLocaleRule: PendingRecallRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRecallRollup) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRecallRollupSequenceRangeRule: PendingRecallRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRecallRollup) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a pending recall rollup.
    final class PendingRecallRollupValidator {
        var rules: [any PendingRecallRollupRule]

        init(rules: [any PendingRecallRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRecallRollup) -> [String] {
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

        func requireValid(_ item: PendingRecallRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRecallRollup]) -> [String: [String]] {
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

    static func defaultPendingRecallRollupValidator() -> PendingRecallRollupValidator {
        return PendingRecallRollupValidator(
            rules: [
                PendingRecallRollupCodePrefixRule(prefix: "ACM"),
                PendingRecallRollupAllowedCodeRule(allowed: ["scheduled", "batched", "adaptive"]),
                PendingRecallRollupRequiredLocaleRule(message: "pending recall rollup needs an entry"),
                PendingRecallRollupSequenceRangeRule(min: 32, max: 64),
            ]
        )
    }
}
