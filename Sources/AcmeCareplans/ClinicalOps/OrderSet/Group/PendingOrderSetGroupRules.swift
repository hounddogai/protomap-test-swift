import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending order set group must pass. Check returns its problems, or none.
    protocol PendingOrderSetGroupRule {
        func check(_ item: PendingOrderSetGroup) -> [String]
    }

    final class PendingOrderSetGroupLabelLengthRule: PendingOrderSetGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingOrderSetGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingOrderSetGroupRequiredCodeRule: PendingOrderSetGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingOrderSetGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingOrderSetGroupCodePrefixRule: PendingOrderSetGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingOrderSetGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending order set group.
    final class PendingOrderSetGroupValidator {
        var rules: [any PendingOrderSetGroupRule]

        init(rules: [any PendingOrderSetGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingOrderSetGroup) -> [String] {
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

        func requireValid(_ item: PendingOrderSetGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingOrderSetGroup]) -> [String: [String]] {
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

    static func defaultPendingOrderSetGroupValidator() -> PendingOrderSetGroupValidator {
        return PendingOrderSetGroupValidator(
            rules: [
                PendingOrderSetGroupLabelLengthRule(maxLength: 86400),
                PendingOrderSetGroupRequiredCodeRule(message: "pending order set group needs a value"),
                PendingOrderSetGroupCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
