import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default interaction agreement must pass. Check returns its problems, or none.
    protocol DefaultInteractionAgreementRule {
        func check(_ item: DefaultInteractionAgreement) -> [String]
    }

    final class DefaultInteractionAgreementCodePrefixRule: DefaultInteractionAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultInteractionAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultInteractionAgreementVersionRangeRule: DefaultInteractionAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultInteractionAgreement) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultInteractionAgreementNameLengthRule: DefaultInteractionAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultInteractionAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultInteractionAgreementRequiredNameRule: DefaultInteractionAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultInteractionAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default interaction agreement.
    final class DefaultInteractionAgreementValidator {
        var rules: [any DefaultInteractionAgreementRule]

        init(rules: [any DefaultInteractionAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultInteractionAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultInteractionAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultInteractionAgreement]) -> [String: [String]] {
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

    static func defaultDefaultInteractionAgreementValidator() -> DefaultInteractionAgreementValidator {
        return DefaultInteractionAgreementValidator(
            rules: [
                DefaultInteractionAgreementCodePrefixRule(prefix: "OPS"),
                DefaultInteractionAgreementVersionRangeRule(min: 32, max: 1000),
                DefaultInteractionAgreementNameLengthRule(maxLength: 3600),
                DefaultInteractionAgreementRequiredNameRule(message: "default interaction agreement needs a value"),
            ]
        )
    }
}
