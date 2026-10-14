import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched denial checkpoint must pass. Check returns its problems, or none.
    protocol BatchedDenialCheckpointRule {
        func check(_ item: BatchedDenialCheckpoint) -> [String]
    }

    final class BatchedDenialCheckpointRequiredLocaleRule: BatchedDenialCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDenialCheckpoint) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDenialCheckpointRequiredCountryRule: BatchedDenialCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDenialCheckpoint) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDenialCheckpointAllowedLocaleRule: BatchedDenialCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedDenialCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is not allowed"]
            }
            return []
        }
    }

    /// Runs every rule of a batched denial checkpoint.
    final class BatchedDenialCheckpointValidator {
        var rules: [any BatchedDenialCheckpointRule]

        init(rules: [any BatchedDenialCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDenialCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedDenialCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDenialCheckpoint]) -> [String: [String]] {
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

    static func defaultBatchedDenialCheckpointValidator() -> BatchedDenialCheckpointValidator {
        return BatchedDenialCheckpointValidator(
            rules: [
                BatchedDenialCheckpointRequiredLocaleRule(message: "batched denial checkpoint needs an entry"),
                BatchedDenialCheckpointRequiredCountryRule(message: "batched denial checkpoint needs this field"),
                BatchedDenialCheckpointAllowedLocaleRule(allowed: ["scheduled", "capped"]),
            ]
        )
    }
}
