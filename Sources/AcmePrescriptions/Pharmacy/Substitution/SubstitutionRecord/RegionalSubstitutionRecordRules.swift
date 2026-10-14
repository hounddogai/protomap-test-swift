import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a regional substitution record must pass. Check returns its problems, or none.
    protocol RegionalSubstitutionRecordRule {
        func check(_ item: RegionalSubstitutionRecord) -> [String]
    }

    final class RegionalSubstitutionRecordAllowedCodeRule: RegionalSubstitutionRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalSubstitutionRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class RegionalSubstitutionRecordRequiredCodeRule: RegionalSubstitutionRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSubstitutionRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalSubstitutionRecordTitleLengthRule: RegionalSubstitutionRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSubstitutionRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalSubstitutionRecordRequiredProcedureCodeRule: RegionalSubstitutionRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSubstitutionRecord) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional substitution record.
    final class RegionalSubstitutionRecordValidator {
        var rules: [any RegionalSubstitutionRecordRule]

        init(rules: [any RegionalSubstitutionRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSubstitutionRecord) -> [String] {
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

        func requireValid(_ item: RegionalSubstitutionRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSubstitutionRecord]) -> [String: [String]] {
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

    static func defaultRegionalSubstitutionRecordValidator() -> RegionalSubstitutionRecordValidator {
        return RegionalSubstitutionRecordValidator(
            rules: [
                RegionalSubstitutionRecordAllowedCodeRule(allowed: ["batched", "adaptive"]),
                RegionalSubstitutionRecordRequiredCodeRule(message: "regional substitution record needs an entry"),
                RegionalSubstitutionRecordTitleLengthRule(maxLength: 16),
                RegionalSubstitutionRecordRequiredProcedureCodeRule(
                    message: "regional substitution record needs an entry"
                ),
            ]
        )
    }
}
