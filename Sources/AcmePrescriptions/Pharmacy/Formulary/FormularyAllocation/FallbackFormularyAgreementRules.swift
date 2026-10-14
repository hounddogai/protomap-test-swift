import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback formulary agreement must pass. Check returns its problems, or none.
    protocol FallbackFormularyAgreementRule {
        func check(_ item: FallbackFormularyAgreement) -> [String]
    }

    final class FallbackFormularyAgreementRequiredCodeRule: FallbackFormularyAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackFormularyAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackFormularyAgreementRevisionRangeRule: FallbackFormularyAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackFormularyAgreement) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackFormularyAgreementCodePrefixRule: FallbackFormularyAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackFormularyAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback formulary agreement.
    final class FallbackFormularyAgreementValidator {
        var rules: [any FallbackFormularyAgreementRule]

        init(rules: [any FallbackFormularyAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackFormularyAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackFormularyAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackFormularyAgreement]) -> [String: [String]] {
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

    static func defaultFallbackFormularyAgreementValidator() -> FallbackFormularyAgreementValidator {
        return FallbackFormularyAgreementValidator(
            rules: [
                FallbackFormularyAgreementRequiredCodeRule(message: "fallback formulary agreement needs a value"),
                FallbackFormularyAgreementRevisionRangeRule(min: 16, max: 64),
                FallbackFormularyAgreementCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
