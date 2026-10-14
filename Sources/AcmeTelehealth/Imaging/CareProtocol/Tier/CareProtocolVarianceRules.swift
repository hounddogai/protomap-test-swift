import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol variance must pass. Check returns its problems, or none.
    protocol CareProtocolVarianceRule {
        func check(_ item: CareProtocolVariance) -> [String]
    }

    final class CareProtocolVarianceCodePrefixRule: CareProtocolVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareProtocolVarianceNotesLengthRule: CareProtocolVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolVariance) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolVarianceRequiredCurrencyRule: CareProtocolVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolVariance) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol variance.
    final class CareProtocolVarianceValidator {
        var rules: [any CareProtocolVarianceRule]

        init(rules: [any CareProtocolVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolVariance]) -> [String: [String]] {
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

    static func defaultCareProtocolVarianceValidator() -> CareProtocolVarianceValidator {
        return CareProtocolVarianceValidator(
            rules: [
                CareProtocolVarianceCodePrefixRule(prefix: "ACM"),
                CareProtocolVarianceNotesLengthRule(maxLength: 80),
                CareProtocolVarianceRequiredCurrencyRule(message: "care protocol variance needs a value"),
            ]
        )
    }
}
