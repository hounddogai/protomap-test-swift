import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy interaction audit must pass. Check returns its problems, or none.
    protocol LegacyInteractionAuditRule {
        func check(_ item: LegacyInteractionAudit) -> [String]
    }

    final class LegacyInteractionAuditCodePrefixRule: LegacyInteractionAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyInteractionAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyInteractionAuditCodeLengthRule: LegacyInteractionAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyInteractionAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyInteractionAuditAllowedChecksumRule: LegacyInteractionAuditRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyInteractionAudit) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is out of range"]
            }
            return []
        }
    }

    final class LegacyInteractionAuditNotesLengthRule: LegacyInteractionAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyInteractionAudit) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyInteractionAuditRequiredChannelRule: LegacyInteractionAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyInteractionAudit) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyInteractionAuditWeightRangeRule: LegacyInteractionAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyInteractionAudit) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a legacy interaction audit.
    final class LegacyInteractionAuditValidator {
        var rules: [any LegacyInteractionAuditRule]

        init(rules: [any LegacyInteractionAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyInteractionAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyInteractionAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyInteractionAudit]) -> [String: [String]] {
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

    static func defaultLegacyInteractionAuditValidator() -> LegacyInteractionAuditValidator {
        return LegacyInteractionAuditValidator(
            rules: [
                LegacyInteractionAuditCodePrefixRule(prefix: "X"),
                LegacyInteractionAuditCodeLengthRule(maxLength: 86400),
                LegacyInteractionAuditAllowedChecksumRule(allowed: ["manual", "legacy", "batched"]),
                LegacyInteractionAuditNotesLengthRule(maxLength: 3600),
                LegacyInteractionAuditRequiredChannelRule(message: "legacy interaction audit needs a value"),
                LegacyInteractionAuditWeightRangeRule(min: 2.5, max: 741.6),
            ]
        )
    }
}
