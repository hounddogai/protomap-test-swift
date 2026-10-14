import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending rounding ledger must pass. Check returns its problems, or none.
    protocol PendingRoundingLedgerRule {
        func check(_ item: PendingRoundingLedger) -> [String]
    }

    final class PendingRoundingLedgerRequiredNameRule: PendingRoundingLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRoundingLedger) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRoundingLedgerCodePrefixRule: PendingRoundingLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingRoundingLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingRoundingLedgerDiagnosisCodeLengthRule: PendingRoundingLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRoundingLedger) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRoundingLedgerAllowedNameRule: PendingRoundingLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingRoundingLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class PendingRoundingLedgerTagsLimitRule: PendingRoundingLedgerRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: PendingRoundingLedger) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    /// Runs every rule of a pending rounding ledger.
    final class PendingRoundingLedgerValidator {
        var rules: [any PendingRoundingLedgerRule]

        init(rules: [any PendingRoundingLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRoundingLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingRoundingLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRoundingLedger]) -> [String: [String]] {
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

    static func defaultPendingRoundingLedgerValidator() -> PendingRoundingLedgerValidator {
        return PendingRoundingLedgerValidator(
            rules: [
                PendingRoundingLedgerRequiredNameRule(message: "pending rounding ledger needs an entry"),
                PendingRoundingLedgerCodePrefixRule(prefix: "OPS"),
                PendingRoundingLedgerDiagnosisCodeLengthRule(maxLength: 120),
                PendingRoundingLedgerAllowedNameRule(allowed: ["rolling", "global", "lenient"]),
                PendingRoundingLedgerTagsLimitRule(maxCount: 120, banned: ["rolling"]),
            ]
        )
    }
}
