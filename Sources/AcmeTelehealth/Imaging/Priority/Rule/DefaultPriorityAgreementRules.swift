import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default priority agreement must pass. Check returns its problems, or none.
    protocol DefaultPriorityAgreementRule {
        func check(_ item: DefaultPriorityAgreement) -> [String]
    }

    final class DefaultPriorityAgreementRequiredRegionRule: DefaultPriorityAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultPriorityAgreement) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultPriorityAgreementAllowedLabelRule: DefaultPriorityAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultPriorityAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is duplicated"]
            }
            return []
        }
    }

    final class DefaultPriorityAgreementRegionLengthRule: DefaultPriorityAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultPriorityAgreement) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default priority agreement.
    final class DefaultPriorityAgreementValidator {
        var rules: [any DefaultPriorityAgreementRule]

        init(rules: [any DefaultPriorityAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultPriorityAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultPriorityAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultPriorityAgreement]) -> [String: [String]] {
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

    static func defaultDefaultPriorityAgreementValidator() -> DefaultPriorityAgreementValidator {
        return DefaultPriorityAgreementValidator(
            rules: [
                DefaultPriorityAgreementRequiredRegionRule(message: "default priority agreement needs this field"),
                DefaultPriorityAgreementAllowedLabelRule(allowed: ["batched"]),
                DefaultPriorityAgreementRegionLengthRule(maxLength: 16),
            ]
        )
    }
}
