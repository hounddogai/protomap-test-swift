import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched denial policy must pass. Check returns its problems, or none.
    protocol BatchedDenialPolicyRule {
        func check(_ item: BatchedDenialPolicy) -> [String]
    }

    final class BatchedDenialPolicyCodePrefixRule: BatchedDenialPolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedDenialPolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedDenialPolicyAllowedBedRule: BatchedDenialPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedDenialPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is expired"]
            }
            return []
        }
    }

    final class BatchedDenialPolicyCodeLengthRule: BatchedDenialPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDenialPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDenialPolicyRequiredCodeRule: BatchedDenialPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDenialPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDenialPolicyTitleLengthRule: BatchedDenialPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDenialPolicy) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedDenialPolicyBedLengthRule: BatchedDenialPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedDenialPolicy) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched denial policy.
    final class BatchedDenialPolicyValidator {
        var rules: [any BatchedDenialPolicyRule]

        init(rules: [any BatchedDenialPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDenialPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedDenialPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDenialPolicy]) -> [String: [String]] {
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

    static func defaultBatchedDenialPolicyValidator() -> BatchedDenialPolicyValidator {
        return BatchedDenialPolicyValidator(
            rules: [
                BatchedDenialPolicyCodePrefixRule(prefix: "REF"),
                BatchedDenialPolicyAllowedBedRule(allowed: ["scheduled"]),
                BatchedDenialPolicyCodeLengthRule(maxLength: 120),
                BatchedDenialPolicyRequiredCodeRule(message: "batched denial policy needs an entry"),
                BatchedDenialPolicyTitleLengthRule(maxLength: 64),
                BatchedDenialPolicyBedLengthRule(maxLength: 64),
            ]
        )
    }
}
