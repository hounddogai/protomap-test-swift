import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy worklist quota must pass. Check returns its problems, or none.
    protocol LegacyWorklistQuotaRule {
        func check(_ item: LegacyWorklistQuota) -> [String]
    }

    final class LegacyWorklistQuotaCodePrefixRule: LegacyWorklistQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyWorklistQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyWorklistQuotaRequiredChecksumRule: LegacyWorklistQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyWorklistQuota) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyWorklistQuotaNameLengthRule: LegacyWorklistQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyWorklistQuota) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyWorklistQuotaCodeLengthRule: LegacyWorklistQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyWorklistQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy worklist quota.
    final class LegacyWorklistQuotaValidator {
        var rules: [any LegacyWorklistQuotaRule]

        init(rules: [any LegacyWorklistQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyWorklistQuota) -> [String] {
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

        func requireValid(_ item: LegacyWorklistQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyWorklistQuota]) -> [String: [String]] {
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

    static func defaultLegacyWorklistQuotaValidator() -> LegacyWorklistQuotaValidator {
        return LegacyWorklistQuotaValidator(
            rules: [
                LegacyWorklistQuotaCodePrefixRule(prefix: "X"),
                LegacyWorklistQuotaRequiredChecksumRule(message: "legacy worklist quota needs a value"),
                LegacyWorklistQuotaNameLengthRule(maxLength: 120),
                LegacyWorklistQuotaCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
