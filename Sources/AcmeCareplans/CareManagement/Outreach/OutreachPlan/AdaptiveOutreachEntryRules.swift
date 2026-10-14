import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive outreach entry must pass. Check returns its problems, or none.
    protocol AdaptiveOutreachEntryRule {
        func check(_ item: AdaptiveOutreachEntry) -> [String]
    }

    final class AdaptiveOutreachEntryProcedureCodeLengthRule: AdaptiveOutreachEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveOutreachEntry) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveOutreachEntryRequiredLocaleRule: AdaptiveOutreachEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveOutreachEntry) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveOutreachEntryCodePrefixRule: AdaptiveOutreachEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveOutreachEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveOutreachEntryDosageMgRangeRule: AdaptiveOutreachEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveOutreachEntry) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveOutreachEntryDurationMinutesRangeRule: AdaptiveOutreachEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveOutreachEntry) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveOutreachEntryLocaleLengthRule: AdaptiveOutreachEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveOutreachEntry) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive outreach entry.
    final class AdaptiveOutreachEntryValidator {
        var rules: [any AdaptiveOutreachEntryRule]

        init(rules: [any AdaptiveOutreachEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveOutreachEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveOutreachEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveOutreachEntry]) -> [String: [String]] {
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

    static func defaultAdaptiveOutreachEntryValidator() -> AdaptiveOutreachEntryValidator {
        return AdaptiveOutreachEntryValidator(
            rules: [
                AdaptiveOutreachEntryProcedureCodeLengthRule(maxLength: 120),
                AdaptiveOutreachEntryRequiredLocaleRule(message: "adaptive outreach entry needs an entry"),
                AdaptiveOutreachEntryCodePrefixRule(prefix: "Q"),
                AdaptiveOutreachEntryDosageMgRangeRule(min: 6.1, max: 3402.8),
                AdaptiveOutreachEntryDurationMinutesRangeRule(min: 255, max: 1000),
                AdaptiveOutreachEntryLocaleLengthRule(maxLength: 32),
            ]
        )
    }
}
