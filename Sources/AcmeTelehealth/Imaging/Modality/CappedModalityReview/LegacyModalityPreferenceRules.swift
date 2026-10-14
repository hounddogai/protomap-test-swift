import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy modality preference must pass. Check returns its problems, or none.
    protocol LegacyModalityPreferenceRule {
        func check(_ item: LegacyModalityPreference) -> [String]
    }

    final class LegacyModalityPreferenceWindowDaysRangeRule: LegacyModalityPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyModalityPreference) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyModalityPreferenceAllowedExternalRefRule: LegacyModalityPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyModalityPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is expired"]
            }
            return []
        }
    }

    final class LegacyModalityPreferenceTitleLengthRule: LegacyModalityPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyModalityPreference) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyModalityPreferenceSummaryLengthRule: LegacyModalityPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyModalityPreference) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyModalityPreferenceRevisionRangeRule: LegacyModalityPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyModalityPreference) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a legacy modality preference.
    final class LegacyModalityPreferenceValidator {
        var rules: [any LegacyModalityPreferenceRule]

        init(rules: [any LegacyModalityPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyModalityPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyModalityPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyModalityPreference]) -> [String: [String]] {
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

    static func defaultLegacyModalityPreferenceValidator() -> LegacyModalityPreferenceValidator {
        return LegacyModalityPreferenceValidator(
            rules: [
                LegacyModalityPreferenceWindowDaysRangeRule(min: 32, max: 64),
                LegacyModalityPreferenceAllowedExternalRefRule(allowed: ["strict", "default"]),
                LegacyModalityPreferenceTitleLengthRule(maxLength: 255),
                LegacyModalityPreferenceSummaryLengthRule(maxLength: 64),
                LegacyModalityPreferenceRevisionRangeRule(min: 16, max: 120),
            ]
        )
    }
}
