import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched witness quota must pass. Check returns its problems, or none.
    protocol BatchedWitnessQuotaRule {
        func check(_ item: BatchedWitnessQuota) -> [String]
    }

    final class BatchedWitnessQuotaCodePrefixRule: BatchedWitnessQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedWitnessQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedWitnessQuotaRequiredCodeRule: BatchedWitnessQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedWitnessQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedWitnessQuotaRequiredOwnerIDRule: BatchedWitnessQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedWitnessQuota) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedWitnessQuotaOwnerIDLengthRule: BatchedWitnessQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedWitnessQuota) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedWitnessQuotaNameLengthRule: BatchedWitnessQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedWitnessQuota) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedWitnessQuotaAllowedOwnerIDRule: BatchedWitnessQuotaRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedWitnessQuota) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a batched witness quota.
    final class BatchedWitnessQuotaValidator {
        var rules: [any BatchedWitnessQuotaRule]

        init(rules: [any BatchedWitnessQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedWitnessQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedWitnessQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedWitnessQuota]) -> [String: [String]] {
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

    static func defaultBatchedWitnessQuotaValidator() -> BatchedWitnessQuotaValidator {
        return BatchedWitnessQuotaValidator(
            rules: [
                BatchedWitnessQuotaCodePrefixRule(prefix: "OPS"),
                BatchedWitnessQuotaRequiredCodeRule(message: "batched witness quota needs this field"),
                BatchedWitnessQuotaRequiredOwnerIDRule(message: "batched witness quota needs this field"),
                BatchedWitnessQuotaOwnerIDLengthRule(maxLength: 86400),
                BatchedWitnessQuotaNameLengthRule(maxLength: 80),
                BatchedWitnessQuotaAllowedOwnerIDRule(allowed: ["legacy", "manual", "legacy"]),
            ]
        )
    }
}
