import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen preference must pass. Check returns its problems, or none.
    protocol SpecimenPreferenceRule {
        func check(_ item: SpecimenPreference) -> [String]
    }

    final class SpecimenPreferenceCodePrefixRule: SpecimenPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SpecimenPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SpecimenPreferenceCeilingRangeRule: SpecimenPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenPreference) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenPreferenceArchivedGuardRule: SpecimenPreferenceRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SpecimenPreference) -> [String] {
            if item.archived && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class SpecimenPreferenceSpecialtyLengthRule: SpecimenPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenPreference) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen preference.
    final class SpecimenPreferenceValidator {
        var rules: [any SpecimenPreferenceRule]

        init(rules: [any SpecimenPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenPreference]) -> [String: [String]] {
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

    static func defaultSpecimenPreferenceValidator() -> SpecimenPreferenceValidator {
        return SpecimenPreferenceValidator(
            rules: [
                SpecimenPreferenceCodePrefixRule(prefix: "X"),
                SpecimenPreferenceCeilingRangeRule(min: 5.2, max: 1315.4),
                SpecimenPreferenceArchivedGuardRule(limit: 0.0),
                SpecimenPreferenceSpecialtyLengthRule(maxLength: 64),
            ]
        )
    }
}
