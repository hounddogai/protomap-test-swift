import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending network threshold must pass. Check returns its problems, or none.
    protocol PendingNetworkThresholdRule {
        func check(_ item: PendingNetworkThreshold) -> [String]
    }

    final class PendingNetworkThresholdLabelLengthRule: PendingNetworkThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingNetworkThreshold) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingNetworkThresholdRequiredCodeRule: PendingNetworkThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingNetworkThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingNetworkThresholdCodePrefixRule: PendingNetworkThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingNetworkThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingNetworkThresholdRequiredLabelRule: PendingNetworkThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingNetworkThreshold) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending network threshold.
    final class PendingNetworkThresholdValidator {
        var rules: [any PendingNetworkThresholdRule]

        init(rules: [any PendingNetworkThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingNetworkThreshold) -> [String] {
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

        func requireValid(_ item: PendingNetworkThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingNetworkThreshold]) -> [String: [String]] {
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

    static func defaultPendingNetworkThresholdValidator() -> PendingNetworkThresholdValidator {
        return PendingNetworkThresholdValidator(
            rules: [
                PendingNetworkThresholdLabelLengthRule(maxLength: 255),
                PendingNetworkThresholdRequiredCodeRule(message: "pending network threshold needs an entry"),
                PendingNetworkThresholdCodePrefixRule(prefix: "Q"),
                PendingNetworkThresholdRequiredLabelRule(message: "pending network threshold needs this field"),
            ]
        )
    }
}
