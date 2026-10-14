import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default transfer agreement must pass. Check returns its problems, or none.
    protocol DefaultTransferAgreementRule {
        func check(_ item: DefaultTransferAgreement) -> [String]
    }

    final class DefaultTransferAgreementRequiredCodeRule: DefaultTransferAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultTransferAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultTransferAgreementRequiredTitleRule: DefaultTransferAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultTransferAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultTransferAgreementMaximumRangeRule: DefaultTransferAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultTransferAgreement) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultTransferAgreementRequiredSourceRule: DefaultTransferAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultTransferAgreement) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default transfer agreement.
    final class DefaultTransferAgreementValidator {
        var rules: [any DefaultTransferAgreementRule]

        init(rules: [any DefaultTransferAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultTransferAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultTransferAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultTransferAgreement]) -> [String: [String]] {
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

    static func defaultDefaultTransferAgreementValidator() -> DefaultTransferAgreementValidator {
        return DefaultTransferAgreementValidator(
            rules: [
                DefaultTransferAgreementRequiredCodeRule(message: "default transfer agreement needs an entry"),
                DefaultTransferAgreementRequiredTitleRule(message: "default transfer agreement needs an entry"),
                DefaultTransferAgreementMaximumRangeRule(min: 2.9, max: 1677.1),
                DefaultTransferAgreementRequiredSourceRule(message: "default transfer agreement needs an entry"),
            ]
        )
    }
}
