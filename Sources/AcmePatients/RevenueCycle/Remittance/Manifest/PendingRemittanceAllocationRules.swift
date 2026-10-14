import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending remittance allocation must pass. Check returns its problems, or none.
    protocol PendingRemittanceAllocationRule {
        func check(_ item: PendingRemittanceAllocation) -> [String]
    }

    final class PendingRemittanceAllocationRequiredExternalRefRule: PendingRemittanceAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRemittanceAllocation) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRemittanceAllocationAllowedSourceRule: PendingRemittanceAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingRemittanceAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is unknown"]
            }
            return []
        }
    }

    final class PendingRemittanceAllocationRequiredLabelRule: PendingRemittanceAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRemittanceAllocation) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRemittanceAllocationSourceLengthRule: PendingRemittanceAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRemittanceAllocation) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRemittanceAllocationCodeLengthRule: PendingRemittanceAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRemittanceAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending remittance allocation.
    final class PendingRemittanceAllocationValidator {
        var rules: [any PendingRemittanceAllocationRule]

        init(rules: [any PendingRemittanceAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRemittanceAllocation) -> [String] {
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

        func requireValid(_ item: PendingRemittanceAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRemittanceAllocation]) -> [String: [String]] {
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

    static func defaultPendingRemittanceAllocationValidator() -> PendingRemittanceAllocationValidator {
        return PendingRemittanceAllocationValidator(
            rules: [
                PendingRemittanceAllocationRequiredExternalRefRule(
                    message: "pending remittance allocation needs a value"
                ),
                PendingRemittanceAllocationAllowedSourceRule(allowed: ["scheduled", "weighted", "weighted"]),
                PendingRemittanceAllocationRequiredLabelRule(
                    message: "pending remittance allocation needs this field"
                ),
                PendingRemittanceAllocationSourceLengthRule(maxLength: 32),
                PendingRemittanceAllocationCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
