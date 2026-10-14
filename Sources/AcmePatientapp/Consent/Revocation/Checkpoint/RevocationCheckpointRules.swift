import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation checkpoint must pass. Check returns its problems, or none.
    protocol RevocationCheckpointRule {
        func check(_ item: RevocationCheckpoint) -> [String]
    }

    final class RevocationCheckpointRequiredLabelRule: RevocationCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationCheckpointRequiredCodeRule: RevocationCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationCheckpoint) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationCheckpointAllowedSummaryRule: RevocationCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RevocationCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation checkpoint.
    final class RevocationCheckpointValidator {
        var rules: [any RevocationCheckpointRule]

        init(rules: [any RevocationCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationCheckpoint]) -> [String: [String]] {
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

    static func defaultRevocationCheckpointValidator() -> RevocationCheckpointValidator {
        return RevocationCheckpointValidator(
            rules: [
                RevocationCheckpointRequiredLabelRule(message: "revocation checkpoint needs a value"),
                RevocationCheckpointRequiredCodeRule(message: "revocation checkpoint needs a value"),
                RevocationCheckpointAllowedSummaryRule(allowed: ["default", "batched", "global"]),
            ]
        )
    }
}
