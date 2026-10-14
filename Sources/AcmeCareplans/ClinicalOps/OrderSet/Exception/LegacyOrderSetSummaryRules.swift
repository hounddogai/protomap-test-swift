import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy order set summary must pass. Check returns its problems, or none.
    protocol LegacyOrderSetSummaryRule {
        func check(_ item: LegacyOrderSetSummary) -> [String]
    }

    final class LegacyOrderSetSummaryAllowedNotesRule: LegacyOrderSetSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyOrderSetSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is unknown"]
            }
            return []
        }
    }

    final class LegacyOrderSetSummaryRequiredNotesRule: LegacyOrderSetSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyOrderSetSummary) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyOrderSetSummaryDosageMgRangeRule: LegacyOrderSetSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyOrderSetSummary) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyOrderSetSummaryCodeLengthRule: LegacyOrderSetSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOrderSetSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyOrderSetSummaryRequiredCountryRule: LegacyOrderSetSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyOrderSetSummary) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyOrderSetSummaryNotesLengthRule: LegacyOrderSetSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOrderSetSummary) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy order set summary.
    final class LegacyOrderSetSummaryValidator {
        var rules: [any LegacyOrderSetSummaryRule]

        init(rules: [any LegacyOrderSetSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyOrderSetSummary) -> [String] {
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

        func requireValid(_ item: LegacyOrderSetSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyOrderSetSummary]) -> [String: [String]] {
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

    static func defaultLegacyOrderSetSummaryValidator() -> LegacyOrderSetSummaryValidator {
        return LegacyOrderSetSummaryValidator(
            rules: [
                LegacyOrderSetSummaryAllowedNotesRule(allowed: ["tiered", "global"]),
                LegacyOrderSetSummaryRequiredNotesRule(message: "legacy order set summary needs a value"),
                LegacyOrderSetSummaryDosageMgRangeRule(min: 7.9, max: 1600.4),
                LegacyOrderSetSummaryCodeLengthRule(maxLength: 120),
                LegacyOrderSetSummaryRequiredCountryRule(message: "legacy order set summary needs this field"),
                LegacyOrderSetSummaryNotesLengthRule(maxLength: 3600),
            ]
        )
    }
}
