import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback panel preference must pass. Check returns its problems, or none.
    protocol FallbackPanelPreferenceRule {
        func check(_ item: FallbackPanelPreference) -> [String]
    }

    final class FallbackPanelPreferenceCodeLengthRule: FallbackPanelPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackPanelPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackPanelPreferenceRequiredFacilityRule: FallbackPanelPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPanelPreference) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPanelPreferenceTitleLengthRule: FallbackPanelPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackPanelPreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackPanelPreferenceRequiredCodeRule: FallbackPanelPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPanelPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPanelPreferenceCodePrefixRule: FallbackPanelPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackPanelPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackPanelPreferenceFacilityLengthRule: FallbackPanelPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackPanelPreference) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback panel preference.
    final class FallbackPanelPreferenceValidator {
        var rules: [any FallbackPanelPreferenceRule]

        init(rules: [any FallbackPanelPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackPanelPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackPanelPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackPanelPreference]) -> [String: [String]] {
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

    static func defaultFallbackPanelPreferenceValidator() -> FallbackPanelPreferenceValidator {
        return FallbackPanelPreferenceValidator(
            rules: [
                FallbackPanelPreferenceCodeLengthRule(maxLength: 32),
                FallbackPanelPreferenceRequiredFacilityRule(message: "fallback panel preference needs a value"),
                FallbackPanelPreferenceTitleLengthRule(maxLength: 255),
                FallbackPanelPreferenceRequiredCodeRule(message: "fallback panel preference needs a value"),
                FallbackPanelPreferenceCodePrefixRule(prefix: "Q"),
                FallbackPanelPreferenceFacilityLengthRule(maxLength: 3600),
            ]
        )
    }
}
