import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a tiered claim quota must pass. Check returns its problems, or none.
    protocol TieredClaimQuotaRule {
        func check(_ item: TieredClaimQuota) -> [String]
    }

    final class TieredClaimQuotaArchivedGuardRule: TieredClaimQuotaRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredClaimQuota) -> [String] {
            if item.archived && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class TieredClaimQuotaCodeLengthRule: TieredClaimQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClaimQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredClaimQuotaRequiredTitleRule: TieredClaimQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredClaimQuotaNameLengthRule: TieredClaimQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClaimQuota) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredClaimQuotaDiagnosisCodeLengthRule: TieredClaimQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredClaimQuota) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredClaimQuotaRequiredDiagnosisCodeRule: TieredClaimQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredClaimQuota) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered claim quota.
    final class TieredClaimQuotaValidator {
        var rules: [any TieredClaimQuotaRule]

        init(rules: [any TieredClaimQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredClaimQuota) -> [String] {
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

        func requireValid(_ item: TieredClaimQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredClaimQuota]) -> [String: [String]] {
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

    static func defaultTieredClaimQuotaValidator() -> TieredClaimQuotaValidator {
        return TieredClaimQuotaValidator(
            rules: [
                TieredClaimQuotaArchivedGuardRule(limit: 255),
                TieredClaimQuotaCodeLengthRule(maxLength: 32),
                TieredClaimQuotaRequiredTitleRule(message: "tiered claim quota needs an entry"),
                TieredClaimQuotaNameLengthRule(maxLength: 255),
                TieredClaimQuotaDiagnosisCodeLengthRule(maxLength: 32),
                TieredClaimQuotaRequiredDiagnosisCodeRule(message: "tiered claim quota needs a value"),
            ]
        )
    }
}
