import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy closure ledger must pass. Check returns its problems, or none.
    protocol LegacyClosureLedgerRule {
        func check(_ item: LegacyClosureLedger) -> [String]
    }

    final class LegacyClosureLedgerTagsLimitRule: LegacyClosureLedgerRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: LegacyClosureLedger) -> [String] {
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

    final class LegacyClosureLedgerRequiredRegionRule: LegacyClosureLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyClosureLedger) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyClosureLedgerCodePrefixRule: LegacyClosureLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyClosureLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyClosureLedgerNameLengthRule: LegacyClosureLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyClosureLedger) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy closure ledger.
    final class LegacyClosureLedgerValidator {
        var rules: [any LegacyClosureLedgerRule]

        init(rules: [any LegacyClosureLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyClosureLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyClosureLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyClosureLedger]) -> [String: [String]] {
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

    static func defaultLegacyClosureLedgerValidator() -> LegacyClosureLedgerValidator {
        return LegacyClosureLedgerValidator(
            rules: [
                LegacyClosureLedgerTagsLimitRule(maxCount: 64, banned: ["seasonal"]),
                LegacyClosureLedgerRequiredRegionRule(message: "legacy closure ledger needs an entry"),
                LegacyClosureLedgerCodePrefixRule(prefix: "ACM"),
                LegacyClosureLedgerNameLengthRule(maxLength: 32),
            ]
        )
    }
}
