import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending charge rollup must pass. Check returns its problems, or none.
    protocol PendingChargeRollupRule {
        func check(_ item: PendingChargeRollup) -> [String]
    }

    final class PendingChargeRollupLabelLengthRule: PendingChargeRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingChargeRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingChargeRollupRequiredReviewerRule: PendingChargeRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingChargeRollup) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingChargeRollupCodePrefixRule: PendingChargeRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingChargeRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingChargeRollupRequiredCodeRule: PendingChargeRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingChargeRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingChargeRollupRequiredLabelRule: PendingChargeRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingChargeRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending charge rollup.
    final class PendingChargeRollupValidator {
        var rules: [any PendingChargeRollupRule]

        init(rules: [any PendingChargeRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingChargeRollup) -> [String] {
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

        func requireValid(_ item: PendingChargeRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingChargeRollup]) -> [String: [String]] {
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

    static func defaultPendingChargeRollupValidator() -> PendingChargeRollupValidator {
        return PendingChargeRollupValidator(
            rules: [
                PendingChargeRollupLabelLengthRule(maxLength: 80),
                PendingChargeRollupRequiredReviewerRule(message: "pending charge rollup needs this field"),
                PendingChargeRollupCodePrefixRule(prefix: "ACM"),
                PendingChargeRollupRequiredCodeRule(message: "pending charge rollup needs a value"),
                PendingChargeRollupRequiredLabelRule(message: "pending charge rollup needs an entry"),
            ]
        )
    }
}
