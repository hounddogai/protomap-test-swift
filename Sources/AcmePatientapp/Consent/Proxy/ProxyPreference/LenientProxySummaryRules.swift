import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient proxy summary must pass. Check returns its problems, or none.
    protocol LenientProxySummaryRule {
        func check(_ item: LenientProxySummary) -> [String]
    }

    final class LenientProxySummaryCodePrefixRule: LenientProxySummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientProxySummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientProxySummaryMinimumRangeRule: LenientProxySummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProxySummary) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientProxySummaryRequiredEncounterIDRule: LenientProxySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProxySummary) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProxySummaryEncounterIDLengthRule: LenientProxySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProxySummary) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient proxy summary.
    final class LenientProxySummaryValidator {
        var rules: [any LenientProxySummaryRule]

        init(rules: [any LenientProxySummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProxySummary) -> [String] {
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

        func requireValid(_ item: LenientProxySummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProxySummary]) -> [String: [String]] {
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

    static func defaultLenientProxySummaryValidator() -> LenientProxySummaryValidator {
        return LenientProxySummaryValidator(
            rules: [
                LenientProxySummaryCodePrefixRule(prefix: "REF"),
                LenientProxySummaryMinimumRangeRule(min: 4.8, max: 1300.7),
                LenientProxySummaryRequiredEncounterIDRule(message: "lenient proxy summary needs an entry"),
                LenientProxySummaryEncounterIDLengthRule(maxLength: 64),
            ]
        )
    }
}
