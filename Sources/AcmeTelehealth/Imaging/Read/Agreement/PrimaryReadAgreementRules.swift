import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary read agreement must pass. Check returns its problems, or none.
    protocol PrimaryReadAgreementRule {
        func check(_ item: PrimaryReadAgreement) -> [String]
    }

    final class PrimaryReadAgreementRequiredAllergyRule: PrimaryReadAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryReadAgreement) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryReadAgreementSequenceRangeRule: PrimaryReadAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryReadAgreement) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryReadAgreementNameLengthRule: PrimaryReadAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryReadAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryReadAgreementSourceLengthRule: PrimaryReadAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryReadAgreement) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryReadAgreementCodeLengthRule: PrimaryReadAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryReadAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary read agreement.
    final class PrimaryReadAgreementValidator {
        var rules: [any PrimaryReadAgreementRule]

        init(rules: [any PrimaryReadAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryReadAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryReadAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryReadAgreement]) -> [String: [String]] {
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

    static func defaultPrimaryReadAgreementValidator() -> PrimaryReadAgreementValidator {
        return PrimaryReadAgreementValidator(
            rules: [
                PrimaryReadAgreementRequiredAllergyRule(message: "primary read agreement needs a value"),
                PrimaryReadAgreementSequenceRangeRule(min: 32, max: 255),
                PrimaryReadAgreementNameLengthRule(maxLength: 120),
                PrimaryReadAgreementSourceLengthRule(maxLength: 16),
                PrimaryReadAgreementCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
