import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap preference must pass. Check returns its problems, or none.
    protocol CareGapPreferenceRule {
        func check(_ item: CareGapPreference) -> [String]
    }

    final class CareGapPreferenceRequiredNameRule: CareGapPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapPreference) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapPreferenceFloorValueRangeRule: CareGapPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapPreference) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareGapPreferenceLimitRangeRule: CareGapPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapPreference) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a care gap preference.
    final class CareGapPreferenceValidator {
        var rules: [any CareGapPreferenceRule]

        init(rules: [any CareGapPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapPreference) -> [String] {
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

        func requireValid(_ item: CareGapPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapPreference]) -> [String: [String]] {
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

    static func defaultCareGapPreferenceValidator() -> CareGapPreferenceValidator {
        return CareGapPreferenceValidator(
            rules: [
                CareGapPreferenceRequiredNameRule(message: "care gap preference needs a value"),
                CareGapPreferenceFloorValueRangeRule(min: 4.3, max: 2835.8),
                CareGapPreferenceLimitRangeRule(min: 80, max: 120),
            ]
        )
    }
}
