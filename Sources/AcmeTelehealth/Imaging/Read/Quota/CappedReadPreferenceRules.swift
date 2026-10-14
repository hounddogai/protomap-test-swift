import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a capped read preference must pass. Check returns its problems, or none.
    protocol CappedReadPreferenceRule {
        func check(_ item: CappedReadPreference) -> [String]
    }

    final class CappedReadPreferenceClinicianIDLengthRule: CappedReadPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedReadPreference) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedReadPreferenceRequiredExternalRefRule: CappedReadPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReadPreference) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedReadPreferenceLimitRangeRule: CappedReadPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedReadPreference) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped read preference.
    final class CappedReadPreferenceValidator {
        var rules: [any CappedReadPreferenceRule]

        init(rules: [any CappedReadPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedReadPreference) -> [String] {
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

        func requireValid(_ item: CappedReadPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedReadPreference]) -> [String: [String]] {
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

    static func defaultCappedReadPreferenceValidator() -> CappedReadPreferenceValidator {
        return CappedReadPreferenceValidator(
            rules: [
                CappedReadPreferenceClinicianIDLengthRule(maxLength: 255),
                CappedReadPreferenceRequiredExternalRefRule(message: "capped read preference needs an entry"),
                CappedReadPreferenceLimitRangeRule(min: 255, max: 86400),
            ]
        )
    }
}
