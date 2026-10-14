import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal accession agreement must pass. Check returns its problems, or none.
    protocol SeasonalAccessionAgreementRule {
        func check(_ item: SeasonalAccessionAgreement) -> [String]
    }

    final class SeasonalAccessionAgreementCodeLengthRule: SeasonalAccessionAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalAccessionAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalAccessionAgreementCodePrefixRule: SeasonalAccessionAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalAccessionAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalAccessionAgreementAllowedTitleRule: SeasonalAccessionAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalAccessionAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal accession agreement.
    final class SeasonalAccessionAgreementValidator {
        var rules: [any SeasonalAccessionAgreementRule]

        init(rules: [any SeasonalAccessionAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalAccessionAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalAccessionAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalAccessionAgreement]) -> [String: [String]] {
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

    static func defaultSeasonalAccessionAgreementValidator() -> SeasonalAccessionAgreementValidator {
        return SeasonalAccessionAgreementValidator(
            rules: [
                SeasonalAccessionAgreementCodeLengthRule(maxLength: 16),
                SeasonalAccessionAgreementCodePrefixRule(prefix: "REF"),
                SeasonalAccessionAgreementAllowedTitleRule(allowed: ["weighted", "capped"]),
            ]
        )
    }
}
