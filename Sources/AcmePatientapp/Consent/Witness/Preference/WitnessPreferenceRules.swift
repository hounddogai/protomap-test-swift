import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness preference must pass. Check returns its problems, or none.
    protocol WitnessPreferenceRule {
        func check(_ item: WitnessPreference) -> [String]
    }

    final class WitnessPreferenceRequiredPayerRule: WitnessPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessPreference) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessPreferenceEndsAtRangeRule: WitnessPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessPreference) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessPreferenceCodeLengthRule: WitnessPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness preference.
    final class WitnessPreferenceValidator {
        var rules: [any WitnessPreferenceRule]

        init(rules: [any WitnessPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessPreference) -> [String] {
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

        func requireValid(_ item: WitnessPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessPreference]) -> [String: [String]] {
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

    static func defaultWitnessPreferenceValidator() -> WitnessPreferenceValidator {
        return WitnessPreferenceValidator(
            rules: [
                WitnessPreferenceRequiredPayerRule(message: "witness preference needs a value"),
                WitnessPreferenceEndsAtRangeRule(min: 16, max: 3600),
                WitnessPreferenceCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
