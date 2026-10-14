import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending result policy must pass. Check returns its problems, or none.
    protocol PendingResultPolicyRule {
        func check(_ item: PendingResultPolicy) -> [String]
    }

    final class PendingResultPolicyDiagnosisCodeLengthRule: PendingResultPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingResultPolicy) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingResultPolicyRetriesRangeRule: PendingResultPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingResultPolicy) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingResultPolicyArchivedGuardRule: PendingResultPolicyRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PendingResultPolicy) -> [String] {
            if item.archived && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class PendingResultPolicyRequiredDiagnosisCodeRule: PendingResultPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingResultPolicy) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingResultPolicyRequiredNameRule: PendingResultPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingResultPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending result policy.
    final class PendingResultPolicyValidator {
        var rules: [any PendingResultPolicyRule]

        init(rules: [any PendingResultPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingResultPolicy) -> [String] {
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

        func requireValid(_ item: PendingResultPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingResultPolicy]) -> [String: [String]] {
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

    static func defaultPendingResultPolicyValidator() -> PendingResultPolicyValidator {
        return PendingResultPolicyValidator(
            rules: [
                PendingResultPolicyDiagnosisCodeLengthRule(maxLength: 120),
                PendingResultPolicyRetriesRangeRule(min: 80, max: 1000),
                PendingResultPolicyArchivedGuardRule(limit: 7.8),
                PendingResultPolicyRequiredDiagnosisCodeRule(message: "pending result policy needs an entry"),
                PendingResultPolicyRequiredNameRule(message: "pending result policy needs this field"),
            ]
        )
    }
}
