import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy accession agreement must pass. Check returns its problems, or none.
    protocol LegacyAccessionAgreementRule {
        func check(_ item: LegacyAccessionAgreement) -> [String]
    }

    final class LegacyAccessionAgreementCodePrefixRule: LegacyAccessionAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyAccessionAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyAccessionAgreementDosageMgRangeRule: LegacyAccessionAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAccessionAgreement) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyAccessionAgreementSummaryLengthRule: LegacyAccessionAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAccessionAgreement) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAccessionAgreementRequiredCodeRule: LegacyAccessionAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAccessionAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAccessionAgreementVisitMinutesRangeRule: LegacyAccessionAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAccessionAgreement) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a legacy accession agreement.
    final class LegacyAccessionAgreementValidator {
        var rules: [any LegacyAccessionAgreementRule]

        init(rules: [any LegacyAccessionAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAccessionAgreement) -> [String] {
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

        func requireValid(_ item: LegacyAccessionAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAccessionAgreement]) -> [String: [String]] {
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

    static func defaultLegacyAccessionAgreementValidator() -> LegacyAccessionAgreementValidator {
        return LegacyAccessionAgreementValidator(
            rules: [
                LegacyAccessionAgreementCodePrefixRule(prefix: "REF"),
                LegacyAccessionAgreementDosageMgRangeRule(min: 3.6, max: 1449.9),
                LegacyAccessionAgreementSummaryLengthRule(maxLength: 16),
                LegacyAccessionAgreementRequiredCodeRule(message: "legacy accession agreement needs a value"),
                LegacyAccessionAgreementVisitMinutesRangeRule(min: 80, max: 120),
            ]
        )
    }
}
