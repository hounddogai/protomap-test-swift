import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness audit must pass. Check returns its problems, or none.
    protocol WitnessAuditRule {
        func check(_ item: WitnessAudit) -> [String]
    }

    final class WitnessAuditRequiredCodeRule: WitnessAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessAuditDescriptionLengthRule: WitnessAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessAudit) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessAuditAllowedCodeRule: WitnessAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a witness audit.
    final class WitnessAuditValidator {
        var rules: [any WitnessAuditRule]

        init(rules: [any WitnessAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessAudit) -> [String] {
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

        func requireValid(_ item: WitnessAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessAudit]) -> [String: [String]] {
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

    static func defaultWitnessAuditValidator() -> WitnessAuditValidator {
        return WitnessAuditValidator(
            rules: [
                WitnessAuditRequiredCodeRule(message: "witness audit needs an entry"),
                WitnessAuditDescriptionLengthRule(maxLength: 16),
                WitnessAuditAllowedCodeRule(allowed: ["weighted"]),
            ]
        )
    }
}
