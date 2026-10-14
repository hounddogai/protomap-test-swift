import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language window must pass. Check returns its problems, or none.
    protocol LanguageWindowRule {
        func check(_ item: LanguageWindow) -> [String]
    }

    final class LanguageWindowRateRangeRule: LanguageWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageWindow) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageWindowEncounterIDLengthRule: LanguageWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageWindow) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageWindowAllowedNameRule: LanguageWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguageWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is expired"]
            }
            return []
        }
    }

    final class LanguageWindowCodePrefixRule: LanguageWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LanguageWindowRequiredLabelRule: LanguageWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageWindowDosageMgRangeRule: LanguageWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageWindow) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a language window.
    final class LanguageWindowValidator {
        var rules: [any LanguageWindowRule]

        init(rules: [any LanguageWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageWindow) -> [String] {
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

        func requireValid(_ item: LanguageWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageWindow]) -> [String: [String]] {
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

    static func defaultLanguageWindowValidator() -> LanguageWindowValidator {
        return LanguageWindowValidator(
            rules: [
                LanguageWindowRateRangeRule(min: 3.6, max: 2385.5),
                LanguageWindowEncounterIDLengthRule(maxLength: 3600),
                LanguageWindowAllowedNameRule(allowed: ["strict", "strict", "strict"]),
                LanguageWindowCodePrefixRule(prefix: "ACM"),
                LanguageWindowRequiredLabelRule(message: "language window needs a value"),
                LanguageWindowDosageMgRangeRule(min: 2.2, max: 1460.3),
            ]
        )
    }
}
