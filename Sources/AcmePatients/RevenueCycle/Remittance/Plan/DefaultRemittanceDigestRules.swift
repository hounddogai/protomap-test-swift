import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default remittance digest must pass. Check returns its problems, or none.
    protocol DefaultRemittanceDigestRule {
        func check(_ item: DefaultRemittanceDigest) -> [String]
    }

    final class DefaultRemittanceDigestRequiredNameRule: DefaultRemittanceDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRemittanceDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRemittanceDigestRequiredNotesRule: DefaultRemittanceDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRemittanceDigest) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRemittanceDigestRequiredCodeRule: DefaultRemittanceDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRemittanceDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default remittance digest.
    final class DefaultRemittanceDigestValidator {
        var rules: [any DefaultRemittanceDigestRule]

        init(rules: [any DefaultRemittanceDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRemittanceDigest) -> [String] {
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

        func requireValid(_ item: DefaultRemittanceDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRemittanceDigest]) -> [String: [String]] {
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

    static func defaultDefaultRemittanceDigestValidator() -> DefaultRemittanceDigestValidator {
        return DefaultRemittanceDigestValidator(
            rules: [
                DefaultRemittanceDigestRequiredNameRule(message: "default remittance digest needs a value"),
                DefaultRemittanceDigestRequiredNotesRule(message: "default remittance digest needs this field"),
                DefaultRemittanceDigestRequiredCodeRule(message: "default remittance digest needs an entry"),
            ]
        )
    }
}
