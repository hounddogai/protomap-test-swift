import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched transfer entry must pass. Check returns its problems, or none.
    protocol BatchedTransferEntryRule {
        func check(_ item: BatchedTransferEntry) -> [String]
    }

    final class BatchedTransferEntryRequiredCodeRule: BatchedTransferEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedTransferEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedTransferEntryDescriptionLengthRule: BatchedTransferEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedTransferEntry) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedTransferEntryAllowedCodeRule: BatchedTransferEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedTransferEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class BatchedTransferEntryLimitRangeRule: BatchedTransferEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedTransferEntry) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedTransferEntryCodePrefixRule: BatchedTransferEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedTransferEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedTransferEntryRequiredClinicianIDRule: BatchedTransferEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedTransferEntry) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched transfer entry.
    final class BatchedTransferEntryValidator {
        var rules: [any BatchedTransferEntryRule]

        init(rules: [any BatchedTransferEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedTransferEntry) -> [String] {
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

        func requireValid(_ item: BatchedTransferEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedTransferEntry]) -> [String: [String]] {
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

    static func defaultBatchedTransferEntryValidator() -> BatchedTransferEntryValidator {
        return BatchedTransferEntryValidator(
            rules: [
                BatchedTransferEntryRequiredCodeRule(message: "batched transfer entry needs this field"),
                BatchedTransferEntryDescriptionLengthRule(maxLength: 86400),
                BatchedTransferEntryAllowedCodeRule(allowed: []),
                BatchedTransferEntryLimitRangeRule(min: 32, max: 120),
                BatchedTransferEntryCodePrefixRule(prefix: "ACM"),
                BatchedTransferEntryRequiredClinicianIDRule(message: "batched transfer entry needs this field"),
            ]
        )
    }
}
