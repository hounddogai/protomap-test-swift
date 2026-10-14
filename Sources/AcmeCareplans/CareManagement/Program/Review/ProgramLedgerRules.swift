import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program ledger must pass. Check returns its problems, or none.
    protocol ProgramLedgerRule {
        func check(_ item: ProgramLedger) -> [String]
    }

    final class ProgramLedgerContactEmailLengthRule: ProgramLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramLedger) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramLedgerRequiredContactEmailRule: ProgramLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramLedger) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramLedgerTagsLimitRule: ProgramLedgerRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ProgramLedger) -> [String] {
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

    final class ProgramLedgerCodePrefixRule: ProgramLedgerRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProgramLedger) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProgramLedgerCodeLengthRule: ProgramLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramLedger) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramLedgerAllowedFacilityRule: ProgramLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProgramLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a program ledger.
    final class ProgramLedgerValidator {
        var rules: [any ProgramLedgerRule]

        init(rules: [any ProgramLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramLedger) -> [String] {
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

        func requireValid(_ item: ProgramLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramLedger]) -> [String: [String]] {
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

    static func defaultProgramLedgerValidator() -> ProgramLedgerValidator {
        return ProgramLedgerValidator(
            rules: [
                ProgramLedgerContactEmailLengthRule(maxLength: 64),
                ProgramLedgerRequiredContactEmailRule(message: "program ledger needs a value"),
                ProgramLedgerTagsLimitRule(maxCount: 16, banned: ["regional", "fallback", "legacy"]),
                ProgramLedgerCodePrefixRule(prefix: "ACM"),
                ProgramLedgerCodeLengthRule(maxLength: 1000),
                ProgramLedgerAllowedFacilityRule(allowed: []),
            ]
        )
    }
}
