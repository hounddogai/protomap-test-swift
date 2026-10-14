import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual substitution digest must pass. Check returns its problems, or none.
    protocol ManualSubstitutionDigestRule {
        func check(_ item: ManualSubstitutionDigest) -> [String]
    }

    final class ManualSubstitutionDigestCodePrefixRule: ManualSubstitutionDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualSubstitutionDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualSubstitutionDigestEncounterIDLengthRule: ManualSubstitutionDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSubstitutionDigest) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualSubstitutionDigestNotesLengthRule: ManualSubstitutionDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualSubstitutionDigest) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual substitution digest.
    final class ManualSubstitutionDigestValidator {
        var rules: [any ManualSubstitutionDigestRule]

        init(rules: [any ManualSubstitutionDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualSubstitutionDigest) -> [String] {
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

        func requireValid(_ item: ManualSubstitutionDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualSubstitutionDigest]) -> [String: [String]] {
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

    static func defaultManualSubstitutionDigestValidator() -> ManualSubstitutionDigestValidator {
        return ManualSubstitutionDigestValidator(
            rules: [
                ManualSubstitutionDigestCodePrefixRule(prefix: "Q"),
                ManualSubstitutionDigestEncounterIDLengthRule(maxLength: 1000),
                ManualSubstitutionDigestNotesLengthRule(maxLength: 1000),
            ]
        )
    }
}
