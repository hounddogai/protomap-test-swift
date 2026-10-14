import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual network preference must pass. Check returns its problems, or none.
    protocol ManualNetworkPreferenceRule {
        func check(_ item: ManualNetworkPreference) -> [String]
    }

    final class ManualNetworkPreferenceRequiredCountryRule: ManualNetworkPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualNetworkPreference) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualNetworkPreferenceOwnerIDLengthRule: ManualNetworkPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkPreference) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualNetworkPreferenceAllowedCurrencyRule: ManualNetworkPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualNetworkPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is duplicated"]
            }
            return []
        }
    }

    final class ManualNetworkPreferenceCountryLengthRule: ManualNetworkPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkPreference) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualNetworkPreferenceLimitRangeRule: ManualNetworkPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualNetworkPreference) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual network preference.
    final class ManualNetworkPreferenceValidator {
        var rules: [any ManualNetworkPreferenceRule]

        init(rules: [any ManualNetworkPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualNetworkPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualNetworkPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualNetworkPreference]) -> [String: [String]] {
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

    static func defaultManualNetworkPreferenceValidator() -> ManualNetworkPreferenceValidator {
        return ManualNetworkPreferenceValidator(
            rules: [
                ManualNetworkPreferenceRequiredCountryRule(message: "manual network preference needs an entry"),
                ManualNetworkPreferenceOwnerIDLengthRule(maxLength: 120),
                ManualNetworkPreferenceAllowedCurrencyRule(allowed: []),
                ManualNetworkPreferenceCountryLengthRule(maxLength: 3600),
                ManualNetworkPreferenceLimitRangeRule(min: 64, max: 80),
            ]
        )
    }
}
