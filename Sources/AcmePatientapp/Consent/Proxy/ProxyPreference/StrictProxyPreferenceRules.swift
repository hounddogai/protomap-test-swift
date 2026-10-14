import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict proxy preference must pass. Check returns its problems, or none.
    protocol StrictProxyPreferenceRule {
        func check(_ item: StrictProxyPreference) -> [String]
    }

    final class StrictProxyPreferenceCodeLengthRule: StrictProxyPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictProxyPreference) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictProxyPreferenceRequiredUnitRule: StrictProxyPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictProxyPreference) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictProxyPreferenceBatchSizeRangeRule: StrictProxyPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictProxyPreference) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict proxy preference.
    final class StrictProxyPreferenceValidator {
        var rules: [any StrictProxyPreferenceRule]

        init(rules: [any StrictProxyPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictProxyPreference) -> [String] {
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

        func requireValid(_ item: StrictProxyPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictProxyPreference]) -> [String: [String]] {
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

    static func defaultStrictProxyPreferenceValidator() -> StrictProxyPreferenceValidator {
        return StrictProxyPreferenceValidator(
            rules: [
                StrictProxyPreferenceCodeLengthRule(maxLength: 32),
                StrictProxyPreferenceRequiredUnitRule(message: "strict proxy preference needs an entry"),
                StrictProxyPreferenceBatchSizeRangeRule(min: 80, max: 3600),
            ]
        )
    }
}
