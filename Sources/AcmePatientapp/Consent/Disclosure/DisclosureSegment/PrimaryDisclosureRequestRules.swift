import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary disclosure request must pass. Check returns its problems, or none.
    protocol PrimaryDisclosureRequestRule {
        func check(_ item: PrimaryDisclosureRequest) -> [String]
    }

    final class PrimaryDisclosureRequestRequiredNameRule: PrimaryDisclosureRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDisclosureRequest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDisclosureRequestTitleLengthRule: PrimaryDisclosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDisclosureRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDisclosureRequestProcedureCodeLengthRule: PrimaryDisclosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDisclosureRequest) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDisclosureRequestCodeLengthRule: PrimaryDisclosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDisclosureRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDisclosureRequestRequiredProcedureCodeRule: PrimaryDisclosureRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDisclosureRequest) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryDisclosureRequestAllowedPayerRule: PrimaryDisclosureRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryDisclosureRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a primary disclosure request.
    final class PrimaryDisclosureRequestValidator {
        var rules: [any PrimaryDisclosureRequestRule]

        init(rules: [any PrimaryDisclosureRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryDisclosureRequest) -> [String] {
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

        func requireValid(_ item: PrimaryDisclosureRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryDisclosureRequest]) -> [String: [String]] {
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

    static func defaultPrimaryDisclosureRequestValidator() -> PrimaryDisclosureRequestValidator {
        return PrimaryDisclosureRequestValidator(
            rules: [
                PrimaryDisclosureRequestRequiredNameRule(message: "primary disclosure request needs an entry"),
                PrimaryDisclosureRequestTitleLengthRule(maxLength: 120),
                PrimaryDisclosureRequestProcedureCodeLengthRule(maxLength: 64),
                PrimaryDisclosureRequestCodeLengthRule(maxLength: 80),
                PrimaryDisclosureRequestRequiredProcedureCodeRule(message: "primary disclosure request needs a value"),
                PrimaryDisclosureRequestAllowedPayerRule(allowed: []),
            ]
        )
    }
}
