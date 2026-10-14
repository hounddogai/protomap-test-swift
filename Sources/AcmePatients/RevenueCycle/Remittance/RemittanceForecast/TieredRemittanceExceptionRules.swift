import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered remittance exception must pass. Check returns its problems, or none.
    protocol TieredRemittanceExceptionRule {
        func check(_ item: TieredRemittanceException) -> [String]
    }

    final class TieredRemittanceExceptionSpecialtyLengthRule: TieredRemittanceExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRemittanceException) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRemittanceExceptionRequiredSpecialtyRule: TieredRemittanceExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRemittanceException) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRemittanceExceptionCodePrefixRule: TieredRemittanceExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredRemittanceException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredRemittanceExceptionRequiredSummaryRule: TieredRemittanceExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRemittanceException) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRemittanceExceptionTitleLengthRule: TieredRemittanceExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRemittanceException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered remittance exception.
    final class TieredRemittanceExceptionValidator {
        var rules: [any TieredRemittanceExceptionRule]

        init(rules: [any TieredRemittanceExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRemittanceException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredRemittanceException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRemittanceException]) -> [String: [String]] {
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

    static func defaultTieredRemittanceExceptionValidator() -> TieredRemittanceExceptionValidator {
        return TieredRemittanceExceptionValidator(
            rules: [
                TieredRemittanceExceptionSpecialtyLengthRule(maxLength: 255),
                TieredRemittanceExceptionRequiredSpecialtyRule(message: "tiered remittance exception needs an entry"),
                TieredRemittanceExceptionCodePrefixRule(prefix: "REF"),
                TieredRemittanceExceptionRequiredSummaryRule(message: "tiered remittance exception needs a value"),
                TieredRemittanceExceptionTitleLengthRule(maxLength: 64),
            ]
        )
    }
}
