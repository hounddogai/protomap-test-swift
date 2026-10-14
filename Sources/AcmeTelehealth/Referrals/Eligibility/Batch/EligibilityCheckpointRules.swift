import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility checkpoint must pass. Check returns its problems, or none.
    protocol EligibilityCheckpointRule {
        func check(_ item: EligibilityCheckpoint) -> [String]
    }

    final class EligibilityCheckpointRequiredTitleRule: EligibilityCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityCheckpoint) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityCheckpointPinnedGuardRule: EligibilityCheckpointRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: EligibilityCheckpoint) -> [String] {
            if item.pinned && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class EligibilityCheckpointProcedureCodeLengthRule: EligibilityCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityCheckpoint) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityCheckpointAllowedProcedureCodeRule: EligibilityCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility checkpoint.
    final class EligibilityCheckpointValidator {
        var rules: [any EligibilityCheckpointRule]

        init(rules: [any EligibilityCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityCheckpoint]) -> [String: [String]] {
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

    static func defaultEligibilityCheckpointValidator() -> EligibilityCheckpointValidator {
        return EligibilityCheckpointValidator(
            rules: [
                EligibilityCheckpointRequiredTitleRule(message: "eligibility checkpoint needs an entry"),
                EligibilityCheckpointPinnedGuardRule(limit: 32),
                EligibilityCheckpointProcedureCodeLengthRule(maxLength: 255),
                EligibilityCheckpointAllowedProcedureCodeRule(allowed: ["seasonal", "regional"]),
            ]
        )
    }
}
