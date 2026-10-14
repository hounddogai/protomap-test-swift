import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default care protocol audit must pass. Check returns its problems, or none.
    protocol DefaultCareProtocolAuditRule {
        func check(_ item: DefaultCareProtocolAudit) -> [String]
    }

    final class DefaultCareProtocolAuditCodePrefixRule: DefaultCareProtocolAuditRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultCareProtocolAudit) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolAuditCodeLengthRule: DefaultCareProtocolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCareProtocolAudit) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolAuditTitleLengthRule: DefaultCareProtocolAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCareProtocolAudit) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolAuditRequiredTitleRule: DefaultCareProtocolAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCareProtocolAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCareProtocolAuditMaximumRangeRule: DefaultCareProtocolAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCareProtocolAudit) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolAuditRequiredCodeRule: DefaultCareProtocolAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCareProtocolAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default care protocol audit.
    final class DefaultCareProtocolAuditValidator {
        var rules: [any DefaultCareProtocolAuditRule]

        init(rules: [any DefaultCareProtocolAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCareProtocolAudit) -> [String] {
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

        func requireValid(_ item: DefaultCareProtocolAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCareProtocolAudit]) -> [String: [String]] {
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

    static func defaultDefaultCareProtocolAuditValidator() -> DefaultCareProtocolAuditValidator {
        return DefaultCareProtocolAuditValidator(
            rules: [
                DefaultCareProtocolAuditCodePrefixRule(prefix: "Q"),
                DefaultCareProtocolAuditCodeLengthRule(maxLength: 80),
                DefaultCareProtocolAuditTitleLengthRule(maxLength: 64),
                DefaultCareProtocolAuditRequiredTitleRule(message: "default care protocol audit needs an entry"),
                DefaultCareProtocolAuditMaximumRangeRule(min: 8.9, max: 4097.5),
                DefaultCareProtocolAuditRequiredCodeRule(message: "default care protocol audit needs a value"),
            ]
        )
    }
}
