import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language agreement must pass. Check returns its problems, or none.
    protocol LanguageAgreementRule {
        func check(_ item: LanguageAgreement) -> [String]
    }

    final class LanguageAgreementCodePrefixRule: LanguageAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LanguageAgreementQuantityRangeRule: LanguageAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageAgreement) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguageAgreementRequiredNameRule: LanguageAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a language agreement.
    final class LanguageAgreementValidator {
        var rules: [any LanguageAgreementRule]

        init(rules: [any LanguageAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageAgreement) -> [String] {
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

        func requireValid(_ item: LanguageAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageAgreement]) -> [String: [String]] {
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

    static func defaultLanguageAgreementValidator() -> LanguageAgreementValidator {
        return LanguageAgreementValidator(
            rules: [
                LanguageAgreementCodePrefixRule(prefix: "OPS"),
                LanguageAgreementQuantityRangeRule(min: 32, max: 64),
                LanguageAgreementRequiredNameRule(message: "language agreement needs a value"),
            ]
        )
    }
}
