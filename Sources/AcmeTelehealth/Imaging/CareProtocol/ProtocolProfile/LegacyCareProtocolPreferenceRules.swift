import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy care protocol preference must pass. Check returns its problems, or none.
    protocol LegacyCareProtocolPreferenceRule {
        func check(_ item: LegacyCareProtocolPreference) -> [String]
    }

    final class LegacyCareProtocolPreferenceRequiredExternalRefRule: LegacyCareProtocolPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCareProtocolPreference) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCareProtocolPreferenceRequiredTitleRule: LegacyCareProtocolPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCareProtocolPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCareProtocolPreferenceAllowedPhoneRule: LegacyCareProtocolPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyCareProtocolPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is not allowed"]
            }
            return []
        }
    }

    final class LegacyCareProtocolPreferenceVisitMinutesRangeRule: LegacyCareProtocolPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCareProtocolPreference) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyCareProtocolPreferenceCopayRangeRule: LegacyCareProtocolPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCareProtocolPreference) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy care protocol preference.
    final class LegacyCareProtocolPreferenceValidator {
        var rules: [any LegacyCareProtocolPreferenceRule]

        init(rules: [any LegacyCareProtocolPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCareProtocolPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyCareProtocolPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCareProtocolPreference]) -> [String: [String]] {
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

    static func defaultLegacyCareProtocolPreferenceValidator() -> LegacyCareProtocolPreferenceValidator {
        return LegacyCareProtocolPreferenceValidator(
            rules: [
                LegacyCareProtocolPreferenceRequiredExternalRefRule(
                    message: "legacy care protocol preference needs a value"
                ),
                LegacyCareProtocolPreferenceRequiredTitleRule(
                    message: "legacy care protocol preference needs this field"
                ),
                LegacyCareProtocolPreferenceAllowedPhoneRule(allowed: []),
                LegacyCareProtocolPreferenceVisitMinutesRangeRule(min: 16, max: 1000),
                LegacyCareProtocolPreferenceCopayRangeRule(min: 8.5, max: 1904.6),
            ]
        )
    }
}
