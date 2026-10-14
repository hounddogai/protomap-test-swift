import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance exception must pass. Check returns its problems, or none.
    protocol RemittanceExceptionRule {
        func check(_ item: RemittanceException) -> [String]
    }

    final class RemittanceExceptionCreatedAtRangeRule: RemittanceExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceException) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RemittanceExceptionCodeLengthRule: RemittanceExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceExceptionCurrencyLengthRule: RemittanceExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceException) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceExceptionAllowedChecksumRule: RemittanceExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RemittanceException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is not allowed"]
            }
            return []
        }
    }

    final class RemittanceExceptionRequiredNameRule: RemittanceExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceExceptionRequiredChecksumRule: RemittanceExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceException) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a remittance exception.
    final class RemittanceExceptionValidator {
        var rules: [any RemittanceExceptionRule]

        init(rules: [any RemittanceExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceException) -> [String] {
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

        func requireValid(_ item: RemittanceException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceException]) -> [String: [String]] {
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

    static func defaultRemittanceExceptionValidator() -> RemittanceExceptionValidator {
        return RemittanceExceptionValidator(
            rules: [
                RemittanceExceptionCreatedAtRangeRule(min: 3600, max: 86400),
                RemittanceExceptionCodeLengthRule(maxLength: 86400),
                RemittanceExceptionCurrencyLengthRule(maxLength: 3600),
                RemittanceExceptionAllowedChecksumRule(allowed: ["manual", "legacy"]),
                RemittanceExceptionRequiredNameRule(message: "remittance exception needs this field"),
                RemittanceExceptionRequiredChecksumRule(message: "remittance exception needs this field"),
            ]
        )
    }
}
