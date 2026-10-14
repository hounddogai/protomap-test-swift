import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending recall quota must pass. Check returns its problems, or none.
    protocol PendingRecallQuotaRule {
        func check(_ item: PendingRecallQuota) -> [String]
    }

    final class PendingRecallQuotaScoreRangeRule: PendingRecallQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingRecallQuota) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingRecallQuotaNotesLengthRule: PendingRecallQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRecallQuota) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRecallQuotaRequiredCodeRule: PendingRecallQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRecallQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRecallQuotaRequiredSpecialtyRule: PendingRecallQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRecallQuota) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRecallQuotaCodePrefixRule: PendingRecallQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingRecallQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingRecallQuotaRequiredNotesRule: PendingRecallQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRecallQuota) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending recall quota.
    final class PendingRecallQuotaValidator {
        var rules: [any PendingRecallQuotaRule]

        init(rules: [any PendingRecallQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRecallQuota) -> [String] {
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

        func requireValid(_ item: PendingRecallQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRecallQuota]) -> [String: [String]] {
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

    static func defaultPendingRecallQuotaValidator() -> PendingRecallQuotaValidator {
        return PendingRecallQuotaValidator(
            rules: [
                PendingRecallQuotaScoreRangeRule(min: 8.3, max: 4669.4),
                PendingRecallQuotaNotesLengthRule(maxLength: 3600),
                PendingRecallQuotaRequiredCodeRule(message: "pending recall quota needs an entry"),
                PendingRecallQuotaRequiredSpecialtyRule(message: "pending recall quota needs an entry"),
                PendingRecallQuotaCodePrefixRule(prefix: "Q"),
                PendingRecallQuotaRequiredNotesRule(message: "pending recall quota needs this field"),
            ]
        )
    }
}
