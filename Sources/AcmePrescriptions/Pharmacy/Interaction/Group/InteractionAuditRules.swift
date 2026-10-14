import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction audit must pass. Check returns its problems, or none.
    protocol InteractionAuditRule {
        func check(_ item: InteractionAudit) -> [String]
    }

    final class InteractionAuditNameLengthRule: InteractionAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionAudit) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionAuditCodePrefixRule: InteractionAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InteractionAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InteractionAuditLabelLengthRule: InteractionAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionAudit) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionAuditCodeLengthRule: InteractionAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction audit.
    final class InteractionAuditValidator {
        var rules: [any InteractionAuditRule]

        init(rules: [any InteractionAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionAudit) -> [String] {
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

        func requireValid(_ item: InteractionAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionAudit]) -> [String: [String]] {
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

    static func defaultInteractionAuditValidator() -> InteractionAuditValidator {
        return InteractionAuditValidator(
            rules: [
                InteractionAuditNameLengthRule(maxLength: 3600),
                InteractionAuditCodePrefixRule(prefix: "OPS"),
                InteractionAuditLabelLengthRule(maxLength: 80),
                InteractionAuditCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
