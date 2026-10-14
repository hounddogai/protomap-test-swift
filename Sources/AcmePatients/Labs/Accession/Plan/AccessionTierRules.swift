import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession tier must pass. Check returns its problems, or none.
    protocol AccessionTierRule {
        func check(_ item: AccessionTier) -> [String]
    }

    final class AccessionTierNotesLengthRule: AccessionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionTier) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionTierEncounterIDLengthRule: AccessionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionTier) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionTierAllowedCodeRule: AccessionTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class AccessionTierRequiredCodeRule: AccessionTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a accession tier.
    final class AccessionTierValidator {
        var rules: [any AccessionTierRule]

        init(rules: [any AccessionTierRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionTier]) -> [String: [String]] {
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

    static func defaultAccessionTierValidator() -> AccessionTierValidator {
        return AccessionTierValidator(
            rules: [
                AccessionTierNotesLengthRule(maxLength: 64),
                AccessionTierEncounterIDLengthRule(maxLength: 16),
                AccessionTierAllowedCodeRule(allowed: ["weighted", "legacy"]),
                AccessionTierRequiredCodeRule(message: "accession tier needs an entry"),
            ]
        )
    }
}
