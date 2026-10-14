import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution summary must pass. Check returns its problems, or none.
    protocol SubstitutionSummaryRule {
        func check(_ item: SubstitutionSummary) -> [String]
    }

    final class SubstitutionSummaryExternalRefLengthRule: SubstitutionSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionSummary) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionSummaryArchivedGuardRule: SubstitutionSummaryRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SubstitutionSummary) -> [String] {
            if item.archived && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class SubstitutionSummaryCodePrefixRule: SubstitutionSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SubstitutionSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SubstitutionSummaryNameLengthRule: SubstitutionSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionSummary) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution summary.
    final class SubstitutionSummaryValidator {
        var rules: [any SubstitutionSummaryRule]

        init(rules: [any SubstitutionSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionSummary]) -> [String: [String]] {
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

    static func defaultSubstitutionSummaryValidator() -> SubstitutionSummaryValidator {
        return SubstitutionSummaryValidator(
            rules: [
                SubstitutionSummaryExternalRefLengthRule(maxLength: 32),
                SubstitutionSummaryArchivedGuardRule(limit: 120),
                SubstitutionSummaryCodePrefixRule(prefix: "Q"),
                SubstitutionSummaryNameLengthRule(maxLength: 120),
            ]
        )
    }
}
