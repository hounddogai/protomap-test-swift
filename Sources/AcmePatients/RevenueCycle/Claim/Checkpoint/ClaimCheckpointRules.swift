import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim checkpoint must pass. Check returns its problems, or none.
    protocol ClaimCheckpointRule {
        func check(_ item: ClaimCheckpoint) -> [String]
    }

    final class ClaimCheckpointRequiredNameRule: ClaimCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimCheckpoint) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimCheckpointBatchSizeRangeRule: ClaimCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimCheckpoint) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClaimCheckpointAllowedCodeRule: ClaimCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a claim checkpoint.
    final class ClaimCheckpointValidator {
        var rules: [any ClaimCheckpointRule]

        init(rules: [any ClaimCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimCheckpoint) -> [String] {
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

        func requireValid(_ item: ClaimCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimCheckpoint]) -> [String: [String]] {
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

    static func defaultClaimCheckpointValidator() -> ClaimCheckpointValidator {
        return ClaimCheckpointValidator(
            rules: [
                ClaimCheckpointRequiredNameRule(message: "claim checkpoint needs an entry"),
                ClaimCheckpointBatchSizeRangeRule(min: 32, max: 64),
                ClaimCheckpointAllowedCodeRule(allowed: ["adaptive", "adaptive"]),
            ]
        )
    }
}
