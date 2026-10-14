import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped eligibility checkpoint must pass. Check returns its problems, or none.
    protocol CappedEligibilityCheckpointRule {
        func check(_ item: CappedEligibilityCheckpoint) -> [String]
    }

    final class CappedEligibilityCheckpointCodePrefixRule: CappedEligibilityCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedEligibilityCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedEligibilityCheckpointTitleLengthRule: CappedEligibilityCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedEligibilityCheckpoint) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedEligibilityCheckpointAllowedProcedureCodeRule: CappedEligibilityCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedEligibilityCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is missing"]
            }
            return []
        }
    }

    final class CappedEligibilityCheckpointRequiredProcedureCodeRule: CappedEligibilityCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedEligibilityCheckpoint) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedEligibilityCheckpointCodeLengthRule: CappedEligibilityCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedEligibilityCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped eligibility checkpoint.
    final class CappedEligibilityCheckpointValidator {
        var rules: [any CappedEligibilityCheckpointRule]

        init(rules: [any CappedEligibilityCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedEligibilityCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedEligibilityCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedEligibilityCheckpoint]) -> [String: [String]] {
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

    static func defaultCappedEligibilityCheckpointValidator() -> CappedEligibilityCheckpointValidator {
        return CappedEligibilityCheckpointValidator(
            rules: [
                CappedEligibilityCheckpointCodePrefixRule(prefix: "X"),
                CappedEligibilityCheckpointTitleLengthRule(maxLength: 64),
                CappedEligibilityCheckpointAllowedProcedureCodeRule(allowed: ["strict", "pending"]),
                CappedEligibilityCheckpointRequiredProcedureCodeRule(
                    message: "capped eligibility checkpoint needs a value"
                ),
                CappedEligibilityCheckpointCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
