import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession preference must pass. Check returns its problems, or none.
    protocol AccessionPreferenceRule {
        func check(_ item: AccessionPreference) -> [String]
    }

    final class AccessionPreferenceAcuityRangeRule: AccessionPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionPreference) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionPreferenceCreatedAtRangeRule: AccessionPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionPreference) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionPreferenceRequiredCodeRule: AccessionPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionPreferenceAllowedTitleRule: AccessionPreferenceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionPreference) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    final class AccessionPreferencePatientRefLengthRule: AccessionPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionPreference) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionPreferenceDosageMgRangeRule: AccessionPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionPreference) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession preference.
    final class AccessionPreferenceValidator {
        var rules: [any AccessionPreferenceRule]

        init(rules: [any AccessionPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionPreference) -> [String] {
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

        func requireValid(_ item: AccessionPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionPreference]) -> [String: [String]] {
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

    static func defaultAccessionPreferenceValidator() -> AccessionPreferenceValidator {
        return AccessionPreferenceValidator(
            rules: [
                AccessionPreferenceAcuityRangeRule(min: 80, max: 1000),
                AccessionPreferenceCreatedAtRangeRule(min: 80, max: 86400),
                AccessionPreferenceRequiredCodeRule(message: "accession preference needs an entry"),
                AccessionPreferenceAllowedTitleRule(allowed: ["strict"]),
                AccessionPreferencePatientRefLengthRule(maxLength: 32),
                AccessionPreferenceDosageMgRangeRule(min: 5.7, max: 845.5),
            ]
        )
    }
}
