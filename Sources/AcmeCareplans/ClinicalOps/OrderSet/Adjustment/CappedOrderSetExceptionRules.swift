import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a capped order set exception must pass. Check returns its problems, or none.
    protocol CappedOrderSetExceptionRule {
        func check(_ item: CappedOrderSetException) -> [String]
    }

    final class CappedOrderSetExceptionAllowedCodeRule: CappedOrderSetExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedOrderSetException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class CappedOrderSetExceptionCodeLengthRule: CappedOrderSetExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedOrderSetException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedOrderSetExceptionRequiredLabelRule: CappedOrderSetExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedOrderSetException) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedOrderSetExceptionCodePrefixRule: CappedOrderSetExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedOrderSetException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped order set exception.
    final class CappedOrderSetExceptionValidator {
        var rules: [any CappedOrderSetExceptionRule]

        init(rules: [any CappedOrderSetExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedOrderSetException) -> [String] {
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

        func requireValid(_ item: CappedOrderSetException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedOrderSetException]) -> [String: [String]] {
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

    static func defaultCappedOrderSetExceptionValidator() -> CappedOrderSetExceptionValidator {
        return CappedOrderSetExceptionValidator(
            rules: [
                CappedOrderSetExceptionAllowedCodeRule(allowed: []),
                CappedOrderSetExceptionCodeLengthRule(maxLength: 16),
                CappedOrderSetExceptionRequiredLabelRule(message: "capped order set exception needs a value"),
                CappedOrderSetExceptionCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
