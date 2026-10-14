import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol agreement must pass. Check returns its problems, or none.
    protocol CareProtocolAgreementRule {
        func check(_ item: CareProtocolAgreement) -> [String]
    }

    final class CareProtocolAgreementRequiredTitleRule: CareProtocolAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolAgreementExternalRefLengthRule: CareProtocolAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolAgreement) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolAgreementRateRangeRule: CareProtocolAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolAgreement) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolAgreementRequiredNameRule: CareProtocolAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolAgreementRequiredCodeRule: CareProtocolAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolAgreementTitleLengthRule: CareProtocolAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol agreement.
    final class CareProtocolAgreementValidator {
        var rules: [any CareProtocolAgreementRule]

        init(rules: [any CareProtocolAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolAgreement) -> [String] {
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

        func requireValid(_ item: CareProtocolAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolAgreement]) -> [String: [String]] {
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

    static func defaultCareProtocolAgreementValidator() -> CareProtocolAgreementValidator {
        return CareProtocolAgreementValidator(
            rules: [
                CareProtocolAgreementRequiredTitleRule(message: "care protocol agreement needs this field"),
                CareProtocolAgreementExternalRefLengthRule(maxLength: 1000),
                CareProtocolAgreementRateRangeRule(min: 0.3, max: 3998.9),
                CareProtocolAgreementRequiredNameRule(message: "care protocol agreement needs an entry"),
                CareProtocolAgreementRequiredCodeRule(message: "care protocol agreement needs a value"),
                CareProtocolAgreementTitleLengthRule(maxLength: 1000),
            ]
        )
    }
}
