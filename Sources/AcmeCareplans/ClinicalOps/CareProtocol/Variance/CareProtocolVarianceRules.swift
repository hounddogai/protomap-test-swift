import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol variance must pass. Check returns its problems, or none.
    protocol CareProtocolVarianceRule {
        func check(_ item: CareProtocolVariance) -> [String]
    }

    final class CareProtocolVarianceRequiredCodeRule: CareProtocolVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolVarianceRequiredSpecialtyRule: CareProtocolVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolVariance) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolVarianceAllowedCodeRule: CareProtocolVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class CareProtocolVarianceCodeLengthRule: CareProtocolVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolVarianceBudgetRangeRule: CareProtocolVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolVariance) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
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
                CareProtocolVarianceRequiredCodeRule(message: "care protocol variance needs a value"),
                CareProtocolVarianceRequiredSpecialtyRule(message: "care protocol variance needs this field"),
                CareProtocolVarianceAllowedCodeRule(allowed: []),
                CareProtocolVarianceCodeLengthRule(maxLength: 16),
                CareProtocolVarianceBudgetRangeRule(min: 2.8, max: 286.0),
            ]
        )
    }
}
