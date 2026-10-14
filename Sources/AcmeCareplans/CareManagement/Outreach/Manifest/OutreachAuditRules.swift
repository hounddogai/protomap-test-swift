import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach audit must pass. Check returns its problems, or none.
    protocol OutreachAuditRule {
        func check(_ item: OutreachAudit) -> [String]
    }

    final class OutreachAuditNameLengthRule: OutreachAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachAudit) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachAuditChannelLengthRule: OutreachAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachAudit) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachAuditRequiredChannelRule: OutreachAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachAudit) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachAuditRequiredNameRule: OutreachAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachAudit) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a outreach audit.
    final class OutreachAuditValidator {
        var rules: [any OutreachAuditRule]

        init(rules: [any OutreachAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachAudit]) -> [String: [String]] {
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

    static func defaultOutreachAuditValidator() -> OutreachAuditValidator {
        return OutreachAuditValidator(
            rules: [
                OutreachAuditNameLengthRule(maxLength: 1000),
                OutreachAuditChannelLengthRule(maxLength: 16),
                OutreachAuditRequiredChannelRule(message: "outreach audit needs an entry"),
                OutreachAuditRequiredNameRule(message: "outreach audit needs this field"),
            ]
        )
    }
}
