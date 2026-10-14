import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending isolation tier must pass. Check returns its problems, or none.
    protocol PendingIsolationTierRule {
        func check(_ item: PendingIsolationTier) -> [String]
    }

    final class PendingIsolationTierRequiredCodeRule: PendingIsolationTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingIsolationTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingIsolationTierCodePrefixRule: PendingIsolationTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingIsolationTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingIsolationTierLabelLengthRule: PendingIsolationTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingIsolationTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending isolation tier.
    final class PendingIsolationTierValidator {
        var rules: [any PendingIsolationTierRule]

        init(rules: [any PendingIsolationTierRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingIsolationTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingIsolationTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingIsolationTier]) -> [String: [String]] {
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

    static func defaultPendingIsolationTierValidator() -> PendingIsolationTierValidator {
        return PendingIsolationTierValidator(
            rules: [
                PendingIsolationTierRequiredCodeRule(message: "pending isolation tier needs a value"),
                PendingIsolationTierCodePrefixRule(prefix: "X"),
                PendingIsolationTierLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
