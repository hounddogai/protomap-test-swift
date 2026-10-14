import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled cleaning quota must pass. Check returns its problems, or none.
    protocol ScheduledCleaningQuotaRule {
        func check(_ item: ScheduledCleaningQuota) -> [String]
    }

    final class ScheduledCleaningQuotaExternalRefLengthRule: ScheduledCleaningQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCleaningQuota) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCleaningQuotaCodePrefixRule: ScheduledCleaningQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledCleaningQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledCleaningQuotaGraceDaysRangeRule: ScheduledCleaningQuotaRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCleaningQuota) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledCleaningQuotaChecksumLengthRule: ScheduledCleaningQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCleaningQuota) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCleaningQuotaCodeLengthRule: ScheduledCleaningQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCleaningQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled cleaning quota.
    final class ScheduledCleaningQuotaValidator {
        var rules: [any ScheduledCleaningQuotaRule]

        init(rules: [any ScheduledCleaningQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCleaningQuota) -> [String] {
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

        func requireValid(_ item: ScheduledCleaningQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCleaningQuota]) -> [String: [String]] {
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

    static func defaultScheduledCleaningQuotaValidator() -> ScheduledCleaningQuotaValidator {
        return ScheduledCleaningQuotaValidator(
            rules: [
                ScheduledCleaningQuotaExternalRefLengthRule(maxLength: 16),
                ScheduledCleaningQuotaCodePrefixRule(prefix: "REF"),
                ScheduledCleaningQuotaGraceDaysRangeRule(min: 32, max: 255),
                ScheduledCleaningQuotaChecksumLengthRule(maxLength: 255),
                ScheduledCleaningQuotaCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
